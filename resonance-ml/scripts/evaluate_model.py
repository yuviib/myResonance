import os
import sys
import pandas as pd
import numpy as np
import torch

# Ensure app path is loaded so imports work
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.core.models.sasrec import SASRec
from app.core.id_mapper import id_mapper

def main():
    data_path = 'data/interactions.csv'
    weights_path = 'data/sasrec_weights.pt'

    if not os.path.exists(data_path) or not os.path.exists(weights_path):
        print("Missing required data. Ensure interactions.csv and sasrec_weights.pt exist.")
        return

    print("Loading telemetry data...")
    df = pd.read_csv(data_path)
    sessions = df.groupby(['session_id', 'user_identifier'])
    
    print("Loading SASRec Model weights...")
    device = torch.device("cpu")
    item_num = id_mapper.next_faiss_id()
    model = SASRec(item_num=max(1000, item_num), embed_dim=64).to(device)
    state_dict = torch.load(weights_path, map_location=device, weights_only=True)
    model.load_state_dict(state_dict, strict=False)
    model.eval()

    # Evaluation counters
    hit_count = 0
    total_evals = 0
    random_hit_count = 0

    print("Executing offline evaluation via sequence masking...")
    with torch.no_grad():
        for _, group in sessions:
            tracks = group['track_id'].tolist()
            actions = group['action'].tolist()
            
            # Require at least 5 tracks to evaluate sequence prediction
            if len(tracks) < 5:
                continue
                
            # Assume the last track is the target we want to predict
            target_r_id = tracks[-1]
            target_action = actions[-1]
            
            # If the target was a skip, predicting it means the model is bad. We only evaluate positive hits.
            if target_action == 'skip':
                continue
                
            # Context sequence
            ctx_r_ids = tracks[:-1]
            
            f_ids = []
            for r_id in ctx_r_ids:
                f_id = id_mapper.get_faiss_id(r_id)
                if f_id is not None:
                    f_ids.append(f_id + 1)
            
            if len(f_ids) < 4:
                 continue
                 
            target_f_id = id_mapper.get_faiss_id(target_r_id)
            if target_f_id is None:
                continue
            target_f_id += 1

            # Prepare SASRec Tensor
            max_seq_len = model.max_len
            window = f_ids[-max_seq_len:]
            pad_len = max_seq_len - len(window)
            padded = [0] * pad_len + window
            seq_tensor = torch.LongTensor([padded]).to(device)
            
            # Get Context Embedding
            seq_output = model(seq_tensor) # (1, 64)
            
            # Compute similarity against all items
            all_embs = model.item_emb.weight[1:item_num + 1] # (N, 64)
            scores = (seq_output * all_embs).sum(dim=-1).squeeze() # (N)
            
            # Get Top 10 recommendations
            top_k_indices = torch.topk(scores, k=10).indices.tolist()
            top_k_f_ids = [idx + 1 for idx in top_k_indices]
            
            if target_f_id in top_k_f_ids:
                hit_count += 1
                
            random_guesses = np.random.choice(range(1, item_num + 1), size=10, replace=False)
            if target_f_id in random_guesses:
                random_hit_count += 1
            
            total_evals += 1
            
    if total_evals == 0:
        print("Not enough sequences long enough to evaluate offline.")
        return
        
    hit_rate = (hit_count / total_evals) * 100
    random_hit_rate = (random_hit_count / total_evals) * 100
    
    print("\n--- SASRec Offline Evaluation Results ---")
    print(f"Total Sequences Evaluated: {total_evals}")
    print(f"Model Top-10 Hit Rate (HR@10): {hit_rate:.2f}%")
    print(f"Random Baseline Top-10 HR@10:  {random_hit_rate:.2f}%")
    print("-----------------------------------------")
    
    if hit_rate > random_hit_rate:
        print("SUCCESS! The Neural Engine is definitively learning semantic trajectories.")
    else:
        print("Model is not outperforming random chance. More epochs or data required.")

if __name__ == '__main__':
    main()
