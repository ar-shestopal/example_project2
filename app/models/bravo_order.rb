class BravoOrder < Order
  include OrdersConcern
  belongs_to :product
  has_one :profile

  def ==(other)
    [self.address_line_1, self.address_line_2, self.city, self.country, self.zip] == [other.address_line_1, other.address_line_2, other.city, other.country, other.zip]
  end
end
