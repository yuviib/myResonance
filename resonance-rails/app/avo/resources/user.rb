class Avo::Resources::User < Avo::BaseResource
  self.title = :email
  self.includes = []
  self.search = {
    query: -> { query.ransack(email_cont: params[:q]).result }
  }

  def fields
    field :id, as: :id
    field :email, as: :text, sortable: true
    field :created_at, as: :date_time, sortable: true
  end
end
