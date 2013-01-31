require File.dirname(__FILE__) + '/../../spec_helper'

describe Droom::Folders do
  context "model with has_folder" do
    before :each do
      build_model :cabinet do
        attr_accessible :slug
        has_many :draws
        string :slug
        has_folder
      end
      build_model :draw do
        attr_accessible :slug
        belongs_to :cabinet
        integer :cabinet_id
        string :slug
        has_folder :within => "cabinet"
      end
      @cabinet = Cabinet.create(:slug => "cab")
      @document = FactoryGirl.create(:document)
    end
    it "has_many :documents" do
      @cabinet.should have_many(:documents)
    end
    it "has_one :folder" do
      @cabinet.should have_one(:folder)
    end
    it "should receive documents" do
      @cabinet.receive_document(@document)
      @document.folder_id.should eq @cabinet.folder.id
      @cabinet.documents.should include @document
    end
    it "should add documents" do
      @cabinet.add_document(:file => Rack::Test::UploadedFile.new('/private/var/www/gems/droom/spec/fixtures/images/rat.png', 'image/png'))
      @cabinet.documents.length.should eq 1
      @cabinet.documents.first.folder_id.should eq @cabinet.folder.id
    end
    it "adding document to child model should create a subfolder of the parent model's folder" do
      @draw = @cabinet.draws.create(:slug => "draw")
      @draw.receive_document(@document)
      @draw.folder.parent_id.should_not be_nil
      @draw.folder.parent_id.should eq @cabinet.folder.id
    end
  end

end
