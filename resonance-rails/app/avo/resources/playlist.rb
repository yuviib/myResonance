class Avo::Resources::Playlist < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :title, as: :text
    field :description, as: :textarea
    field :image_url, as: :text
  end
end
