require 'spec_helper_active_record'

describe "Trailblazer::Finder::Adapters::ActiveRecord::Sorting", :sorting do
  after do
    Product.delete_all
    Product.reset_pk_sequence
  end

  before do
    Product.delete_all
    Product.reset_pk_sequence
  end

  class TestARFinder < Trailblazer::Finder
    features Sorting
    adapters ActiveRecord

    entity_type { Product.all }

    sortable_by :name, :price, :created_at

    filter_by :name
    filter_by :price
  end

  def finder_with_sort(sort = nil, filters = {})
    TestARFinder.new filter: (sort.nil? ? {} : { sort: sort }).merge(filters)
  end

  describe 'sorting' do

    it 'sorts results based on the sort option desc' do
      5.times { |i| Product.create! price: i }

      finder = finder_with_sort 'price desc'
      expect(finder.results.map(&:price)).to eq [4, 3, 2, 1, 0]
    end

    it 'sorts results based on the sort option asc' do
      5.times { |i| Product.create! price: i }

      finder = finder_with_sort 'price asc'
      expect(finder.results.map(&:price)).to eq [0, 1, 2, 3, 4]
    end

    it 'defaults to defaulted database sort if none is set' do
      5.times { |i| Product.create! name: "Name#{i}" }

      finder = finder_with_sort
      expect(finder.results.map(&:name)).to eq %w[Name0 Name1 Name2 Name3 Name4]
    end

    it 'ignores invalid sort values' do
      finder = finder_with_sort 'invalid attribute'
      expect { finder.results.to_a }.not_to raise_error
    end

    it 'can handle renames of sorting in joins' do
      older_category = Category.create! title: 'older'
      newer_category = Category.create! title: 'newer'

      product_of_newer_category = Product.create! name: 'older product', category: newer_category
      product_of_older_category = Product.create! name: 'newer product', category: older_category

      finder = finder_with_sort 'created_at desc', category: ''

      expect(finder.results.map(&:name)).to eq [product_of_older_category.name, product_of_newer_category.name]
    end
  end

  describe 'sorting by multiple' do
    before do
      5.times do |i|
        Product.create name: "Name#{i}", price: "1#{i}"
      end
      Product.create name: 'Name3', price: '8'
    end

    it 'sorts by multiple columns name asc and price asc' do
      finder = finder_with_sort 'name asc, price asc'
      expect(finder.results.map(&:name)).to eq %w[Name0 Name1 Name2 Name3 Name3 Name4]
      expect(finder.results.map(&:price)).to eq [10, 11, 12, 8, 13, 14]
    end

    it 'sorts by multiple columns name asc and price desc' do
      finder = finder_with_sort 'name asc, price desc'
      expect(finder.results.map(&:name)).to eq %w[Name0 Name1 Name2 Name3 Name3 Name4]
      expect(finder.results.map(&:price)).to eq [10, 11, 12, 13, 8, 14]
    end

    it 'sorts by multiple columns name desc and price desc' do
      finder = finder_with_sort 'name desc, price desc'
      expect(finder.results.map(&:name)).to eq %w[Name4 Name3 Name3 Name2 Name1 Name0]
      expect(finder.results.map(&:price)).to eq [14, 13, 8, 12, 11, 10]
    end
  end

  it_behaves_like 'a sorting feature'
end
