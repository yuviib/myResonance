class Avo::Resources::Track < Avo::BaseResource
  self.title = :title
  self.includes = [:album]
  self.search = {
    query: -> { query.ransack(title_cont: params[:q]).result }
  }

  def fields
    field :id, as: :id
    field :title, as: :text, sortable: true
    field :duration_seconds, as: :number
    field :spotify_id, as: :text
    field :album, as: :belongs_to
  end
end
