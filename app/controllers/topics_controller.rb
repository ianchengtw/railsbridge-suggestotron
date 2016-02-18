class TopicsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy, :upvote, :devote]
  before_action :set_topic, only: [:show, :edit, :update, :destroy]

  # GET /topics
  # GET /topics.json
  def index
    if current_user
      @user_id = current_user.id
    else
      @user_id = -1
    end

    # sql = "
    #   SELECT
    #     T.id
    #     ,T.title
    #     ,T.votes_count
    #     ,SUM(CASE WHEN V.value > 0 THEN V.value ELSE 0 END) AS pos_sum
    #     ,SUM(CASE WHEN V.value < 0 THEN V.value ELSE 0 END) AS neg_sum
    #     ,SUM(V.value) AS sum
    #     ,SUM(CASE WHEN V.user_id = #{@user_id} THEN 1 ELSE 0 END) AS isVoted
    #   FROM topics AS T
    #   LEFT JOIN votes AS V ON T.id = V.topic_id
    #   GROUP BY T.id
    #   ORDER BY SUM(V.value) DESC
    # "
    # @topics = Topic.find_by_sql(sql)
    @topics = Topic.joins("LEFT JOIN votes ON topics.id = votes.topic_id")
      .select("topics.id")
      .select("topics.title")
      .select("topics.votes_count")
      .select("SUM(CASE WHEN votes.value > 0 THEN votes.value ELSE 0 END) AS pos_sum")
      .select("SUM(CASE WHEN votes.value < 0 THEN votes.value ELSE 0 END) AS neg_sum")
      .select("SUM(votes.value) AS sum")
      .select("SUM(CASE WHEN votes.user_id = #{@user_id} THEN 1 ELSE 0 END) AS isVoted")
      .group("topics.id")
      .order("SUM(votes.value) DESC")
    # @topics = Topic.joins(:votes).group('topics.id').order('SUM(votes.value) DESC')
    # @topics = Topic.all.order('votes_count DESC')
  end

  # GET /topics/1
  # GET /topics/1.json
  def show
  end

  # GET /topics/new
  def new
    @topic = Topic.new
  end

  # GET /topics/1/edit
  def edit
  end

  # POST /topics
  # POST /topics.json
  def create
    @topic = Topic.new(topic_params)

    respond_to do |format|
      if @topic.save
        format.html { redirect_to topics_path, notice: 'Topic was successfully created.' }
        format.json { render :show, status: :created, location: @topic }
      else
        format.html { render :new }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /topics/1
  # PATCH/PUT /topics/1.json
  def update
    respond_to do |format|
      if @topic.update(topic_params)
        format.html { redirect_to topics_path, notice: 'Topic was successfully updated.' }
        format.json { render :show, status: :ok, location: @topic }
      else
        format.html { render :edit }
        format.json { render json: @topic.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /topics/1
  # DELETE /topics/1.json
  def destroy
    @topic.destroy
    respond_to do |format|
      format.html { redirect_to topics_url, notice: 'Topic was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def upvote
    @topic = Topic.find(params[:id])
    @vote = @topic.votes.build
    @vote.voter = current_user
    @vote.value = 1

    if @vote.save
      flash[:notice] = 'Vote Success'
    else
      flash[:alert] = 'Vote Failed'
    end

    redirect_to(topics_path)
  end

  def devote
    @topic = Topic.find(params[:id])
    @vote = @topic.votes.build
    @vote.voter = current_user
    @vote.value = -1

    if @vote.save
      flash[:notice] = 'Vote Success'
    else
      flash[:alert] = 'Vote Failed'
    end

    redirect_to(topics_path)
  end

  def revote
    @topic = Topic.find(params[:id])
    @votes = @topic.votes.where(user_id: current_user.id)
    @votes.each do |v|
      v.destroy
    end

    flash[:notice] = 'Removed Vote'

    redirect_to(topics_path)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_topic
      @topic = Topic.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def topic_params
      params.require(:topic).permit(:title, :description)
    end
end
