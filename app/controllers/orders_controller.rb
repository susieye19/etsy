class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def purchases
    @orders = Order.all.where(buyer: current_user)
  end

  def sales
    @orders = Order.all.where(seller: current_user)
  end

  # GET /orders
  # GET /orders.json
  def index
    @orders = Order.all
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
  end

  # GET /orders/new
  def new
    @order = Order.new
    @listing = Listing.find(params[:listing_id])
  end

  # GET /orders/1/edit
  def edit
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)
    @listing = Listing.find(params[:listing_id])

    @order.listing_id = @listing.id
    @order.buyer_id = current_user.id
    @order.seller_id = @listing.user_id

    # Set Stripe key and retrieve token
    Stripe.api_key = ENV["STRIPE_API_KEY"]
    token = params[:stripeToken]

    # Charge the buyer's credit card
    begin
      charge = Stripe::Charge.create(
        amount: (100 * @order.listing.price).to_i,
        currency: "usd",
        card: token,
        )
    rescue Stripe::CardError => e
      flash[:danger] = e.message
    end

    if false
      # Transfer funds
      begin
        transfer = Stripe::Transfer.create(
          amount: (100 * @order.listing.price).to_i,
          currency: "usd",
          recipient: @listing.user.token,
        )
      rescue Stripe::CardError => e
        flash[:danger] = e.message
      end
    end    

    respond_to do |format|
      if @order.save
        format.html { redirect_to root_url, notice: 'Order was successfully created.' }
        format.json { render action: 'show', status: :created, location: @order }
      else
        format.html { render action: 'new' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:delivery_address, :delivery_city, :delivery_state)
    end
end
