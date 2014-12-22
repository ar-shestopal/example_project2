class CoordinatesController < ApplicationController
  def index
    @coordinates = Coordinate.all
    respond_to do |format|
      format.json {render json: @coordinates }
    end
  end
end
