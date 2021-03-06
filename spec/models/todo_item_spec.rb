require 'spec_helper'

describe TodoItem do
  subject { FactoryGirl.create(:todo_item) }

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

  context "urgent" do
    it "returns true if item's deadline is less then 24 hours" do
      subject.update_attribute(:deadline, 23.hours.from_now)
      expect(subject.urgent?).to be_true
    end

    it "returns false if item's deadline is 24 hours or more" do
      subject.update_attribute(:deadline, 24.hours.from_now + 1.minute)
      expect(subject.urgent?).to be_false
    end
  end
end
