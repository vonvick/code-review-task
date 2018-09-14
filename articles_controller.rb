class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :find_article_by_slug, only: [:show, :update, :destroy]

  def index
    @articles = Article.all.includes(:user)

    article_options

    @articles_count = @articles.count

    @articles = order_articles(
      order_by: :desc,
      limit: articles_filter(params[:limit], 20),
      offset: articles_filter(params[:offset])
    )
  end

  def feed
    @articles = Article.includes(:user).where(user: current_user.following_users)

    @articles_count = @articles.count

    @articles = order_articles(
      order_by: :desc,
      limit: articles_filter(params[:limit]),
      offset: articles_filter(params[:offset])
    )

    render :index
  end

  def create
    @article = Article.new(article_params)
    @article.user = current_user

    if @article.save
      render :show
    else
      render json: { errors: @article.errors }, status: :unprocessable_entity
    end
  end

  def show; end

  def update
    if @article.user_id == @current_user_id
      @article.update_attributes(article_params)
      render :show
    else
      handle_forbidden_error
    end
  end

  def destroy
    if @article.user_id == @current_user_id
      @article.destroy

      render json: {}, status: :ok
    else
      handle_forbidden_error
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :body, :description, tag_list: [])
  end

  def articles_filter(filter, filter_value: nil)
    return filter if filter.present?

    filter_value
  end

  def handle_forbidden_error
    render json: { errors: { article: ['not owned by user'] } },
           status: :forbidden
  end

  def article_options
    @articles.tagged_with(params[:tag]) if params[:tag].present?
    @articles.authored_by(params[:author]) if params[:author].present?
    @articles.favorited_by(params[:favorited]) if params[:favorited].present?
  end

  def find_articles_by_slug
    @article = Article.find_by_slug!(params[:slug])
  end

  def order_articles(args)
    @articles.order(created_at: args[:order_by])
             .offset(args[:offset])
             .limit(args[:limit])
  end
end
