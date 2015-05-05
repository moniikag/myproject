require 'spec_helper'

describe TodoItem do

  fixtures :all
  subject { todo_items(:todo_item_1)}

  context ".complete" do
    it "returns proper amount of complete items" do
      expect {
        TodoItem.create!(content: "Item 1", deadline: Time.now, completed_at: Time.now)
      }.to change { TodoItem.complete.count }.by(1)
    end
  end

  context ".incomplete" do
    it "returns proper amount of incomplete items" do
      expect {
        TodoItem.create!(content: "Item 1", deadline: Time.now)
      }.to change{TodoItem.incomplete.count}.by(1)
    end
  end

  context "#completed?" do
    it "returns true if todo_item is completed" do
      subject.completed_at = Time.now
      expect(subject.completed?).to eq(true)
    end

    it "returns false if todo_item is not completed" do
      subject.completed_at = nil
      expect(subject.completed?).to eq(false)
    end
  end

  context "#tag_list" do
    it "displays one tag properly" do
      subject.tags.new(name: "urgent")
      expect(subject.tag_list).to eq("urgent")
    end

    it "displays two tags properly" do
      subject.tags.new(name: "urgent")
      subject.tags.new(name: "important")
      expect(subject.tag_list).to eq("urgent, important")
    end

    it "displays three tags properly" do
      subject.tags.new(name: "urgent")
      subject.tags.new(name: "important")
      subject.tags.new(name: "fee")
      expect(subject.tag_list).to eq("urgent, important, fee")
    end
  end

  context "#tag_list=" do
    it "adds new tag to database" do
      expect { 
        subject.tag_list = 'urgent'
      }.to change { Tag.count }.by(1)
      expect(subject.tag_list).to eq("urgent")
    end

    it "properly adds to database two tags given with ', '" do
      expect {
        subject.tag_list = 'urgent, fee'
      }.to change { Tag.count }.by(2)
      expect(subject.tag_list).to eq("urgent, fee")      
    end

    it "properly adds to database two tags given with ' , '" do
      expect { 
        subject.tag_list = 'urgent , fee'
      }.to change { Tag.count }.by(2)
      expect(subject.tag_list).to eq("urgent, fee")      
    end

    it "properly adds to database two tags given with ','" do
      expect {
        subject.tag_list = 'urgent,fee'
      }.to change { Tag.count }.by(2)
      expect(subject.tag_list).to eq("urgent, fee")      
    end

    it "properly adds to database tag consisting of two words" do
      expect {
        subject.tag_list = 'urgent fee'
      }.to change { Tag.count }.by(1)
      expect(subject.tag_list).to eq("urgent fee")      
    end

    context "with existing tag existing" do
      let!(:subject_tag) {tags(:tag_1) }

      it "doesn't add existing tag to database if one tag given" do
        expect {
          subject.tag_list = subject_tag.name
        }.to change { Tag.count }.by(0)
        expect(subject.tag_list).to eq("important")
        expect(subject.tags).to include(subject_tag)
      end

      it "doesn't add existing tag to database if two tags given (old one and new one)" do
        expect {
          subject.tag_list = 'urgent, important'
        }.to change { Tag.count }.by(1)
        expect(subject.tag_list).to eq("urgent, important")
        expect(subject.tags).to include(subject_tag)
      end    
    end
  end 

end