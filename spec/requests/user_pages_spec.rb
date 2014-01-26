require 'spec_helper'

describe "UserPages" do

	subject {page}

	describe "index" do

		let(:user) { FactoryGirl.create(:user) }

		before(:each) do
			sign_in user
			visit users_path
		end

		it { should have_selector('title', text: 'All users') }
		it { should have_selector('h1', text: 'All users') }

		describe "pagination" do
			before(:all) { 30.times { FactoryGirl.create(:user) } }
      	after(:all)  { User.delete_all }

			it { should have_selector('div.pagination') }

			it "should list each user" do
				User.paginate(page: 1).each do |user|
					page.should have_selector('li', text: user.name)
				end
			end
		end

		describe "delete links" do

			it { should_not have_link('delete') }

			describe "as an admin user" do
				let(:admin) { FactoryGirl.create(:admin) }

				before do
					sign_in admin
					visit users_path
				end

				it { should have_link('delete', href: user_path(User.first)) }
				it "should be able to delete another user" do
					expect { click_link('delete') }.to change(User, :count).by(-1)
				end
				it { should_not have_link('delete', href: user_path(admin)) }
			end
		end
	end

	describe "signup page" do

		describe "if not signed in" do
			before {visit signup_path}

			it {should have_selector('h1', text: 'Sign up')}
			it {should have_selector('title', text: 'Sign up')}
		end

		describe "if already signed in" do

			let(:user) { FactoryGirl.create(:user) }
			
			before do
				sign_in user
				visit signup_path
			end

			it { should_not have_selector('h1', text: 'Sign up') }
			it { should_not have_selector('title', text: 'Sign up')}
		end

	end

	describe "signup" do
		before {visit signup_path}

		let(:submit) { "Create my account" }

		describe "with invalid information" do
			it "should not create a user" do
				expect { click_button submit }.not_to change(User, :count)
			end
		end

		describe "with valid information" do
			before do
				fill_in "Name", with: "Example User"
				fill_in "Email", with: "user@example.com"
				fill_in "Password", with: "foobar"
				fill_in "Confirm Password", with: "foobar"
			end

			it "should create a user" do
				expect { click_button submit }.to change(User, :count).by(1)
			end

			describe "after saving the user" do
				before { click_button submit }
				let(:user) { User.find_by_email('user@example.com') }

				it { should have_selector('title', text: user.name) }
				it { should have_selector('div.alert.alert-success', text: 'Welcome') }
				it { should have_link('Sign out') }

				describe "followed by signout" do
					before { click_link "Sign out" }
					it { should have_link('Sign in') }
				end
			end
		end
	end

	describe "signup error" do
		before do
			visit signup_path

			fill_in "Name", with: ""
			fill_in "Email", with: "user@"
			fill_in "Password", with: "foobar"
			fill_in "Confirm Password", with: "barfood" 

			click_button "Create my account"
		end

		describe "after submission" do
			it {should have_content("The form contains 3 errors")}
			it {should have_content("Password doesn't match confirmation")}
			it {should have_content("Name can't be blank")}
			it {should have_content("Email is invalid")}
		end
	end

	describe "on the users profile page" do
		let(:user) { FactoryGirl.create(:user) }
		let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "Foo") }
		let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "Bar") }

		before { visit user_path(user) }

		it { should have_selector('h1', text: user.name) }
		it { should have_selector('title', text: user.name) }

		describe "microposts" do
			it { should have_content(m1.content) }
			it { should have_content(m2.content) }
			it { should have_content(user.microposts.count) }
		end
	end

# ok i changed this a little from the book... not really understanding things here
# wrt microposts showing up on root path, why not test here? also: how to do it? 
# my rspec code doesn't work
# OK I figured out why... because in this test the user isn't signed in yet!
# Besides implementation should be on static_pages_spec.rb, under "Home page for signed in users"

#		describe "on the root page" do
#			before { visit root_path }

#			it { should have_selector('h1', text: user.name) }

#			describe "microposts" do
#				it { should have_content(m1.content) }
#				it { should have_content(m2.content) }
#				it { should have_content(user.microposts.count) }
#			end			
#		end		

	describe "edit" do
		let(:user) { FactoryGirl.create(:user) }
		before do
			sign_in user
			visit edit_user_path(user) 
		end

		describe "page" do
			it { should have_selector('h1', text: "Update your profile") }
			it { should have_selector('title', text: "Edit user") }
			it { should have_link('change', href: 'http://gravatar.com/emails') }
		end

		describe "with invalid information" do
			before { click_button "Save changes" }

			it { should have_content('error') }
		end

		describe "with valid information" do
			let(:new_name) { "New Name" }
			let(:new_email) { "new@example.com" }
			before do
				fill_in "Name", with: new_name
				fill_in "Email", with: new_email
				fill_in "Password", with: user.password
				fill_in "Confirm Password", with: user.password
				click_button "Save changes"
			end

			it { should have_selector('title', text: new_name) }
			it { should have_selector('div.alert.alert-success') }
			it { should have_link('Sign out', href: signout_path) }
			specify { user.reload.name.should == new_name }
			specify { user.reload.email.should == new_email }
		end

		describe "forbidden attributes" do
			let(:params) do
				{ user: {admin: true, password: user.password, 
					password_confirmation: user.password } }
			end

			before do
				sign_in user, no_capybara: true				
			end

			it "should not allow user to assign parameters" do
				expect do 
					put user_path(user), params
				end.to raise_error(ActiveModel::MassAssignmentSecurity::Error)
			end


			specify { expect(user.reload).not_to be_admin }
		end

	end
end
