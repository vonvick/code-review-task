class ArticlesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @articles = Article.all.includes(:user)

    if params[:tag].present?
      @articles = @articles.tagged_with(params[:tag])
    elsif params[:author].present?
      @articles = @articles.authored_by(params[:author])
    elsif params[:favorited].present?
      @articles = @articles.favorited_by(params[:favorited])
    end

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc)
                         .offset(articles_offset)
                         .limit(articles_limit(20))
  end

  def feed
    @articles = Article.includes(:user).where(user: current_user.following_users)

    @articles_count = @articles.count

    @articles = @articles.order(created_at: :desc)
                         .offset(articles_offset)
                         .limit(articles_limit)

    render :index
  end

  def create
    @article = Article.new(article_params)
    @article.user = current_user

    if @article.save
      render :show
    else
      render json: { errors: @article.errors }, status: => 422
    end
  end

  def show
    @article = Article.find_by_slug!(params[:slug])
  end

  def update
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.update_attributes(article_params)
      render :show
    else
      handle_forbidden_error
    end
  end

  def destroy
    @article = Article.find_by_slug!(params[:slug])

    if @article.user_id == @current_user_id
      @article.destroy

      render json: {}
    else
      handle_forbidden_error
    end
  end

  private

  def article_params
    params.require(:article).permit(:title, :body, :description, tag_list: [])
  end

  def articles_limit(limit = nil)
    return params[:limit] if params[:limit].present?

    limit
  end

  def articles_offset(offset = nil)
    return params[:offset] if params[:offset].present?

    offset
  end

  def handle_forbidden_error
    render json: { errors: { article: ['not owned by user'] } },
           status: :forbidden
  end
end
