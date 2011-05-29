require 'spec_helper'

describe "ActiveRecord Model annotated with 'has_eav_behavior' with no options in declaration" do
  fixtures :posts, :post_attributes

  describe "#respond_to?" do
    before( :each ) do
      @blog_post = Post.find_by_title("Following up from my first post.")
    end
    it "should be true when there is an eav attribute" do
      @blog_post.foo = 'bar'
      @blog_post.should respond_to :foo
    end

    it "should be true when the method is defined" do
      method = @blog_post.methods.first
      @blog_post.should respond_to method
    end

    it "should not be true when there is no eav attribute and the method isn't defined" do
      @blog_post.should_not respond_to :no_one_should_ever_write_this_method
    end

    it "should be true when using question marks" do
      @blog_post.example_text = "text"
      @blog_post.example_text?.should be_true
    end

    it "respond_to? eav attribute with question marks" do
      @blog_post.example_text = "text"
         require 'ruby-debug'
         debugger
      @blog_post.respond_to?(:example_text?).should be_true
    end
  end

  it "should return true if a value exists" do
    @blog_post = Post.find_by_title("Following up from my first post.")
    @blog_post.id?.should be_true
  end

  it "should have many attributes" do
    post_attr = Post.find_by_title("Hello World").post_attributes
    post_attr[0].should be_instance_of(PostAttribute)
    post_attr.size.should == 3
  end
  
  it "should create new attribute on save" do
    blog_post = Post.find_by_title("Following up from my first post.")
    blog_post.new_attribute = 'new_value'

    new_attribute = blog_post.post_attributes.to_a.find do |attribute|
      attribute.name == 'new_attribute'
    end
    new_attribute.should_not be_nil

    blog_post.new_attribute.should == 'new_value'
    PostAttribute.find_by_name_and_post_id('new_attribute', 2).should be_nil
    blog_post.save!

    PostAttribute.find_by_name_and_post_id('new_attribute', 2).value.should == 'new_value'
    blog_post.new_attribute.should == 'new_value'

  end

  it "should delete attribute" do
    blog_post = Post.find_by_title("Hello World")
    blog_post.send(:write_attribute, 'comment', nil)

    comment = blog_post.post_attributes.find_by_name('comment')
    comment.should_not be_nil

    blog_post.comment.should be_nil
    blog_post.save!

    blog_post.comment.should be_nil

    comment = blog_post.post_attributes.find_by_name('comment')
    blog_post.comment.should be_nil
    PostAttribute.find_by_id(1).should be_nil
  end
  
  it "should write eav attributes to attributes table" do
    blog_post = Post.find_by_title("Hello World")
    blog_post.intro = 'Blah Blah Blah'
    blog_post.intro.should == 'Blah Blah Blah'
    PostAttribute.find(2).value.should_not == 'Blah Blah Blah'
    blog_post.save!
    PostAttribute.find(2).value.should == 'Blah Blah Blah'
  end
  
  it "should return nil when attribute does not exist" do
    blog_post = Post.find_by_title("Hello World")
    blog_post.not_exist.should be_nil
  end
  
  it "should use method missing to make attribute seem as native property" do
    blog_post = Post.find_by_title("Hello World")
    blog_post.comment.should == 'Foo Bar Industries gets two thumbs up'
    blog_post.intro.should == 'We deliver quality foobars to consumers nationwide and around the globe'
    blog_post.teaser.should == 'Coming October 7, the foobarantator'
  end
  
  it "should read attributes using subscript notation" do
    blog_post = Post.find_by_title("Hello World")
    blog_post['comment'].should == 'Foo Bar Industries gets two thumbs up'
    blog_post['intro'].should == 'We deliver quality foobars to consumers nationwide and around the globe'
    blog_post['teaser'].should == 'Coming October 7, the foobarantator'
  end
  
  it "should read the attribute when invoking 'read_attribute'" do
    blog_post = Post.find_by_title("Hello World")
    blog_post.comment.should == 'Foo Bar Industries gets two thumbs up'
    blog_post.intro.should == 'We deliver quality foobars to consumers nationwide and around the globe'
    blog_post.teaser.should == 'Coming October 7, the foobarantator'
  end
  
end
