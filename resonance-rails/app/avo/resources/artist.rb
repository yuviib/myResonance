class Avo::Resources::Artist < Avo::BaseResource
  self.title = :name
  self.includes = []
  self.search = {
    query: -> { query.ransack(name_cont: params[:q]).result }
  }

  def fields
    field :id, as: :id
    field :name, as: :text, sortable: true
    field :image_url, as: :text
    field :bio, as: :trix
    field :albums, as: :has_many
  end
end
