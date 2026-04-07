import torch
import torch.optim as optim
import pandas as pd
import numpy as np
import logging
import os

from app.core.models.sasrec import SASRec
from app.core.id_mapper import id_mapper
from tqdm import tqdm

logger = logging.getLogger(__name__)


class IncrementalTrainer:
    def __init__(self, model: SASRec, device: torch.device, batch_size: int = 64):
        self.model = model
        self.device = device
        self.batch_size = batch_size
        # lr=1e-4 with batching is equivalent in stability to lr=1e-5 with batch_size=1,
        # but converges far faster. Still conservative enough to preserve zero-shot embeddings.
        self.optimizer = optim.AdamW(self.model.parameters(), lr=1e-4, weight_decay=1e-4)

    def _bpr_loss(self, pos_scores, neg_scores):
        """
        Bayesian Personalised Ranking loss.
        Maximises the margin between positive and negative item scores.
        pos_scores, neg_scores: (batch,)
        """
        return -torch.log(torch.sigmoid(pos_scores - neg_scores) + 1e-8).mean()

    def _gather_item_score(self, seq_output, item_ids):
        """
        seq_output : (batch, embed_dim)
        item_ids   : (batch,)
        Returns dot-product scores (batch,).
        """
        item_embs = self.model.item_emb(item_ids)  # (batch, embed_dim)
        return (seq_output * item_embs).sum(dim=-1)  # (batch,)

    def _build_triples(self, df, item_num):
        """
        Pre-processes the dataframe into training triples once.
        Reused across all epochs to avoid re-parsing the CSV.

        Each triple is (padded_input, pos_target_id, neg_f_ids, all_pos_f_ids).
        neg_f_ids is the pool of hard negatives for this session (may be empty).
        all_pos_f_ids is the full positive sequence used to avoid false negatives
        during random negative sampling.
        """
        sessions = df.groupby(['session_id', 'user_identifier'])
        max_seq_len = self.model.max_len
        triples = []

        for _, group in sessions:
            pos_group = group[group['action'].isin(['play', 'complete', 'like'])].copy()
            if len(pos_group) < 2:
                continue

            f_ids = []
            for r_id in pos_group['track_id']:
                f_id = id_mapper.get_faiss_id(r_id)
                if f_id is not None:
                    f_ids.append(f_id + 1)

            if len(f_ids) < 2:
                continue

            neg_group = group[group['action'] == 'skip']
            neg_f_ids = []
            for r_id in neg_group['track_id']:
                f_id = id_mapper.get_faiss_id(r_id)
                if f_id is not None:
                    neg_f_ids.append(f_id + 1)

            for end in range(2, len(f_ids) + 1):
                window = f_ids[max(0, end - max_seq_len): end]
                input_seq = window[:-1]
                pos_target_id = window[-1]

                pad_len = max_seq_len - len(input_seq)
                padded = [0] * pad_len + input_seq

                triples.append((padded, pos_target_id, neg_f_ids, f_ids))

        return triples

    def _sample_negatives(self, neg_f_ids_list, pos_f_ids_list, item_num, batch_size):
        """
        Sample one negative ID per triple in the batch.
        Uses hard negatives (skips) when available, falls back to random sampling.
        Returns a list of negative IDs of length batch_size.
        """
        neg_ids = []
        for neg_f_ids, pos_f_ids in zip(neg_f_ids_list, pos_f_ids_list):
            if neg_f_ids:
                neg_ids.append(neg_f_ids[np.random.randint(len(neg_f_ids))])
            else:
                neg_id = np.random.randint(1, item_num + 1)
                pos_set = set(pos_f_ids)
                while neg_id in pos_set:
                    neg_id = np.random.randint(1, item_num + 1)
                neg_ids.append(neg_id)
        return neg_ids

    def fine_tune(self, data_path: str, epochs: int = 1):
        if not os.path.exists(data_path):
            logger.warning(f"No telemetry data found at {data_path}. Skipping training.")
            return False

        df = pd.read_csv(data_path)
        if df.empty:
            logger.info("Telemetry CSV is empty. Skipping.")
            return False

        required_cols = {'session_id', 'user_identifier', 'track_id', 'action'}
        if not required_cols.issubset(df.columns):
            logger.error(f"CSV missing required columns. Found: {list(df.columns)}")
            return False

        item_num = self.model.item_num

        # Build triples once — reused across all epochs
        logger.info("Building training triples from telemetry...")
        triples = self._build_triples(df, item_num)

        if not triples:
            logger.info("No valid training triples found. Model unchanged.")
            return False

        n_batches = int(np.ceil(len(triples) / self.batch_size))
        logger.info(
            f"Built {len(triples)} triples → {n_batches} batches of {self.batch_size}. "
            f"Running {epochs} epoch(s)..."
        )

        self.model.train()
        total_loss = 0.0
        total_updates = 0

        for epoch in range(epochs):
            epoch_loss = 0.0
            epoch_updates = 0

            # Shuffle triples each epoch to prevent ordering bias
            np.random.shuffle(triples)

            pbar = tqdm(range(n_batches), desc=f"Epoch {epoch + 1}/{epochs}", unit="batch")

            for batch_idx in pbar:
                start = batch_idx * self.batch_size
                batch = triples[start: start + self.batch_size]

                # Unzip batch into parallel lists
                padded_seqs, pos_ids, neg_f_ids_list, pos_f_ids_list = zip(*batch)

                # Sample negatives for this batch
                neg_ids = self._sample_negatives(neg_f_ids_list, pos_f_ids_list, item_num, len(batch))

                # Build tensors — shape: (batch, max_len) and (batch,)
                seq_tensor = torch.LongTensor(padded_seqs).to(self.device)
                pos_tensor = torch.LongTensor(pos_ids).to(self.device)
                neg_tensor = torch.LongTensor(neg_ids).to(self.device)

                self.optimizer.zero_grad()

                # Forward pass — processes entire batch in one shot
                seq_output = self.model(seq_tensor)  # (batch, embed_dim)

                pos_score = self._gather_item_score(seq_output, pos_tensor)  # (batch,)
                neg_score = self._gather_item_score(seq_output, neg_tensor)  # (batch,)

                loss = self._bpr_loss(pos_score, neg_score)
                loss.backward()

                torch.nn.utils.clip_grad_norm_(self.model.parameters(), max_norm=1.0)
                self.optimizer.step()

                epoch_loss += loss.item()
                epoch_updates += 1
                pbar.set_postfix({"loss": f"{epoch_loss / epoch_updates:.4f}"})

            avg_epoch_loss = epoch_loss / epoch_updates
            logger.info(
                f"Epoch {epoch + 1}/{epochs} — Batches: {epoch_updates}, "
                f"Avg BPR Loss: {avg_epoch_loss:.4f}"
            )

            total_loss += epoch_loss
            total_updates += epoch_updates

        avg_loss = total_loss / total_updates
        logger.info(f"Training complete. Total batches: {total_updates}, Overall Avg Loss: {avg_loss:.4f}")

        # Persist weights to disk
        weights_path = "data/sasrec_weights.pt"
        try:
            os.makedirs("data", exist_ok=True)
            torch.save(self.model.state_dict(), weights_path)
            logger.info(f"Persisted SASRec weights to {weights_path}")
        except Exception as e:
            logger.error(f"Failed to persist weights: {e}")

        return True


_training_manager = None


def get_trainer(model, device):
    global _training_manager
    if _training_manager is None:
        _training_manager = IncrementalTrainer(model, device)
    return _training_manager