require 'spec_helper'

describe "UserPages" do

	subject {page}

	describe "signup page" do
		before {visit signup_path}

		it {should have_selector('h1', text: 'Sign up')}
		it {should have_selector('title', text: 'Sign up')}
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
				fill_in "Confirmation", with: "foobar"
			end

			it "should create a user" do
				expect { click_button submit }.to change(User, :count).by(1)
			end
		end
	end

	describe "signup error" do
		before do
			visit signup_path

			fill_in "Name", with: ""
			fill_in "Email", with: "user@"
			fill_in "Password", with: "foobar"
			fill_in "Confirmation", with: "barfood" 

			click_button "Create my account"
		end

		describe "after submission" do
			it {should have_content("The form contains 3 errors")}
			it {should have_content("Password doesn't match confirmation")}
			it {should have_content("Name can't be blank")}
			it {should have_content("Email is invalid")}
		end
	end

	describe "profile page" do
		let(:user) { FactoryGirl.create(:user) }
		before { visit user_path(user) }

		it { should have_selector('h1', text: user.name) }
		it { should have_selector('title', text: user.name) }
	end



end
