require 'rails_helper'

describe ActionController::Base, type: :controller do
  describe '.deserializable_resource' do
    let(:payload) do
      {
        _jsonapi: {
          'data' => {
            'type' => 'users',
            'attributes' => { 'name' => 'Lucas' }
          }
        }
      }
    end

    context 'when using default deserializer' do
      controller do
        deserializable_resource :user

        def create
          render plain: 'ok'
        end
      end

      it 'makes the deserialized resource available in params' do
        post :create, params: payload

        expected = { 'type' => 'users', 'name' => 'Lucas' }
        expect(controller.params[:user]).to eq(expected)
      end

      it 'makes the deserialization mapping available via #jsonapi_pointers' do
        post :create, params: payload

        expected = { name: '/data/attributes/name',
                     type: '/data/type' }
        expect(controller.jsonapi_pointers).to eq(expected)
      end
    end

    context 'when using a customized deserializer' do
      controller do
        deserializable_resource :user do
          attribute(:name) do |val|
            { 'first_name'.to_sym => val }
          end
        end

        def create
          render plain: 'ok'
        end
      end

      it 'makes the deserialized resource available in params' do
        post :create, params: payload

        expected = { 'type' => 'users', 'first_name' => 'Lucas' }
        expect(controller.params[:user]).to eq(expected)
      end

      it 'makes the deserialization mapping available via #jsonapi_pointers' do
        post :create, params: payload

        expected = { first_name: '/data/attributes/name',
                     type: '/data/type' }
        expect(controller.jsonapi_pointers).to eq(expected)
      end
    end

    context 'when using a customized deserializer with key_format' do
      controller do
        deserializable_resource :user do
          key_format(&:capitalize)
        end

        def create
          render plain: 'ok'
        end
      end

      it 'makes the deserialized resource available in params' do
        post :create, params: payload

        expected = { 'type' => 'users', 'Name' => 'Lucas' }
        expect(controller.params[:user]).to eq(expected)
      end

      it 'makes the deserialization mapping available via #jsonapi_pointers' do
        post :create, params: payload

        expected = { Name: '/data/attributes/name',
                     type: '/data/type' }
        expect(controller.jsonapi_pointers).to eq(expected)
      end
    end
  end

  describe '#render' do
    context 'when calling render jsonapi: user' do
      controller do
        def index
          serializer = Class.new(JSONAPI::Serializable::Resource) do
            type :users
            attribute :name
          end
          user = OpenStruct.new(id: 1, name: 'Lucas')

          render jsonapi: user, class: serializer
        end
      end

      subject { JSON.parse(response.body) }
      let(:serialized_user) do
        {
          'data' => {
            'id' => '1',
            'type' => 'users',
            'attributes' => { 'name' => 'Lucas' }
          }
        }
      end

      it 'renders a JSON API success document' do
        get :index

        expect(response.content_type).to eq('application/vnd.api+json')
        is_expected.to eq(serialized_user)
      end
    end

    context 'when specifying a default jsonapi object' do
      controller do
        def index
          render jsonapi: nil
        end

        def jsonapi_object
          { version: '1.0' }
        end
      end

      subject { JSON.parse(response.body) }
      let(:document) do
        {
          'data' => nil,
          'jsonapi' => { 'version' => '1.0' }
        }
      end

      it 'renders a JSON API success document' do
        get :index

        expect(response.content_type).to eq('application/vnd.api+json')
        is_expected.to eq(document)
      end
    end
  end
end
