class HohosController < ApplicationController
  before_action :set_hoho, only: [:show, :edit, :update, :destroy]

  # GET /hohos
  # GET /hohos.json
  def index
    @hohos = Hoho.all
  end

  # GET /hohos/1
  # GET /hohos/1.json
  def show
  end

  # GET /hohos/new
  def new
    @hoho = Hoho.new
  end

  # GET /hohos/1/edit
  def edit
  end

  # POST /hohos
  # POST /hohos.json
  def create
    @hoho = Hoho.new(hoho_params)

    respond_to do |format|
      if @hoho.save
        format.html { redirect_to @hoho, notice: 'Hoho was successfully created.' }
        format.json { render :show, status: :created, location: @hoho }
      else
        format.html { render :new }
        format.json { render json: @hoho.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hohos/1
  # PATCH/PUT /hohos/1.json
  def update
    respond_to do |format|
      if @hoho.update(hoho_params)
        format.html { redirect_to @hoho, notice: 'Hoho was successfully updated.' }
        format.json { render :show, status: :ok, location: @hoho }
      else
        format.html { render :edit }
        format.json { render json: @hoho.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hohos/1
  # DELETE /hohos/1.json
  def destroy
    @hoho.destroy
    respond_to do |format|
      format.html { redirect_to hohos_url, notice: 'Hoho was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hoho
      @hoho = Hoho.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def hoho_params
      params.require(:hoho).permit(:my)
    end
end
