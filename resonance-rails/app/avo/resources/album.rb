class Avo::Resources::Album < Avo::BaseResource
  self.title = :title
  self.includes = [:artist]
  self.search = {
    query: -> { query.ransack(title_cont: params[:q]).result }
  }

  def fields
    field :id, as: :id
    field :title, as: :text, sortable: true
    field :cover_url, as: :text
    field :release_year, as: :number, sortable: true
    field :artist, as: :belongs_to
    field :tracks, as: :has_many
  end
end
