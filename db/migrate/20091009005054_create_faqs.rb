class CreateFaqs < ActiveRecord::Migration
  def self.up
    create_table :faqs do |t|
      t.string :question
      t.string :answer

      t.timestamps
    end
    
    Faq.create(
      :question => "How much is an upgrade?",
      :answer => "$2.95 / month, which includes unlimited groups and tasks.")
      
    Faq.create(
      :question => "How do I cancel my upgrade?",
      :answer => "Go to your PayPal account that you used to buy the subscription, and cancel within PayPal.  Your Quadtask account will be downgraded to the free version automatically.")
  end

  def self.down
    drop_table :faqs
  end
end
