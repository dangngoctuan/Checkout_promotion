require './spec_helper'

class Promotion
  PRODUCT_CODE = '001'
  PRICE_DROPS = 8.5
  TOTAL_OVER = 60
  GET_OFF = 0.9

  def add_promotion(products, basket)
    if basket.count(Promotion::PRODUCT_CODE) >= 2
      @list_products = products.each_with_object([]) do |product, result|
        result << (product[:product_code] == Promotion::PRODUCT_CODE ? self.promotion_prioritize(product) : product)
      end
    end

    @list_products ||= products
    calc_total_price(@list_products)
  end

  def promotion_prioritize(product)
    product[:price] = Promotion::PRICE_DROPS
    product
  end

  def calc_total_price(list_products)
    total = list_products.reduce(0) {|sum, product| sum + product[:price]}
    if total > Promotion::TOTAL_OVER
      return (total * Promotion::GET_OFF).round(2)
    end
    total.round(2)
  end
end

class General
  def initialize(promotional_rules)
    @promotional = promotional_rules
    @basket = []
  end

  def data_products
    [{ product_code: '001', name: 'Lavender heart', price: 9.25 }, { product_code: '002', name: 'Personalised cufflinks', price: 45 }, { product_code: '003', name: 'Kids T-shirt', price: 19.95 }]
  end
end

class Checkout < General
  def scan(item)
    @basket << item
  end

  def get_products
    @basket.each_with_object([]) do |item, result|
      result << data_products.select { |product| product[:product_code] == item }.first
    end
  end

  def total
    @promotional.add_promotion(get_products, @basket)
  end
end

RSpec.describe Checkout do
  let!(:co) { Checkout.new(Promotion.new) }

  def total_not_promotion
    co.get_products.reduce(0) {|sum, product| sum + product[:price]}
  end

  def total_with_promotion
    co.get_products.reduce(0) {|sum, product| sum + (product[:product_code] == '001' ? 8.5 : product[:price])}
  end

  describe '#new' do
    it 'is a new object' do
      expect(co.instance_variable_get(:@basket)).to eq []
      expect(co.instance_variable_get(:@promotional)).to be_kind_of(Promotion)
    end

    it 'is not a new object' do
      expect(co.instance_variable_get(:@promotional)).not_to be_kind_of(String)
    end
  end

  describe '#scan' do
    it 'add item to basket' do
      item = '001'

      expect(co.scan(item)).to eq [item]
    end
  end

  describe '#total' do
    it 'with not Promotion' do
      ['001', '002'].each do |item|
        co.scan(item)
      end

      expect(co.total).to eq total_not_promotion.round(2)
    end

    it 'with only Promotion get off' do
      ['001', '002', '003'].each do |item|
        co.scan(item)
      end

      expect(co.total).to eq (total_not_promotion * 0.9).round(2)
    end

    it 'with only Promotion price drops' do
      ['001', '003', '001'].each do |item|
        co.scan(item)
      end

      expect(co.total).to eq total_with_promotion.round(2)
    end

    it 'with all Promotion' do
      ['001', '003', '001', '002'].each do |item|
        co.scan(item)
      end

      expect(co.total).to eq (total_with_promotion * 0.9).round(2)
    end
  end
end


 # co = Checkout.new(Promotion.new)
 # co.scan('001')
 # co.scan('002')
 # co.scan('003')
 # co.scan('001')
 # price = co.total

 # puts price
