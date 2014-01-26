require 'spec_helper'

describe "Authentication" do

	subject { page }

	describe "signin page" do
		before { visit signin_path }

		it { should have_selector('h1', text: 'Sign in') }
		it { should have_selector('title', text: 'Sign in') }
	end

	describe "signin" do
		before { visit signin_path }

		describe "with invalid information" do
			before { click_button "Sign in" }

			it { should have_selector('title', text: 'Sign in') }
			it { should have_selector('div.alert.alert-error', text: 'Invalid') }
			it { should_not have_link('Profile') }
			it { should_not have_link('Settings') }
			it { should_not have_link('Sign out') }			

			describe "after visiting another page" do
				before { click_link "Home" }
				it { should_not have_selector('div.alert.alert-error') }
			end
		end

		describe "with valid information" do
			let(:user) { FactoryGirl.create(:user) }
			before { sign_in user }

			it { should have_selector('title', text: user.name) }

			it { should have_link('Users', text: users_path) }
			it { should have_link('Profile', href: user_path(user)) }
			it { should have_link('Settings', href: edit_user_path(user)) }
			it { should have_link('Sign out', href: signout_path) }
			it { should_not have_link('Sign in', href: signin_path) }
		end

	end

	describe "authorization" do

		describe "for non-signed-in users" do
			let(:user) { FactoryGirl.create(:user) }

			describe "in the Users controller" do

				describe "visiting the edit page" do
					before { visit edit_user_path(user) }
					it { should have_selector('title', text: 'Sign in') }
				end

				describe "submitting to the update action" do
					before { put user_path(user) }
					specify { response.should redirect_to(signin_path) }
				end

				describe "visiting the user index" do
					before { visit users_path }
					it { should have_selector('title', text: 'Sign in') }
				end
			end

			describe "when attempting to visit a protected page" do
				before do
					visit edit_user_path(user)
					fill_in "Email", with: user.email
					fill_in "Password", with: user.password
					click_button "Sign in"
				end

				# friendly forwarding...

				describe "after signing in" do
					it "should render the desired protected page" do
						page.should have_selector('title', text: 'Edit user')
					end
				end

				describe "subsequent sign in attempts" do
					before do
						click_link "Sign out"
						sign_in user
					end

					it "should not still render the previous desired protected page" do
						page.should_not have_selector('title', text: 'Edit user')
					end
				end

			end

			describe "in the Microposts controller" do

				describe "submitting to the create action" do
					before { post microposts_path }
					specify { response.should redirect_to(signin_path) }
				end

				describe "submitting to the destroy action" do
					let!(:micropost) { FactoryGirl.create(:micropost) }
					before do 
						delete micropost_path(micropost) 
					end
					specify { response.should redirect_to(signin_path) }
				end

			end

		end

		describe "as wrong user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") } 
			before { sign_in user }

			describe "visiting Users#edit page" do
				before { visit edit_user_path(wrong_user) }
				it { should_not have_selector('title', text: full_title('Edit user')) }
			end

			describe "submitting a PUT request to the Users#update action" do
				before { put user_path(wrong_user) }
#				specify { response.should redirect_to(root_path) }
# should is being deprecated, trying out expect instead...
				it { expect{response}.to redirect_to(root_path) }
			end
		end

		describe "as non-admin user" do
			let(:user) { FactoryGirl.create(:user) }
			let(:non_admin) { FactoryGirl.create(:user) }

			before { sign_in non_admin }

			describe "submitting a DELETE request to the Users#destroy action" do
				before { delete user_path(user) }
				specify { response.should redirect_to(root_path) }
			end
		end

		describe "as admin user" do
			# write test here to make sure admin user does not delete him/herself
			let(:admin) { FactoryGirl.create(:admin) }

			before { sign_in admin }

			describe "submitting a DELETE request for him/herself" do
#				before { delete user_path(admin) }
#				specify { response.should redirect_to(root_path) }
# 				why this no work? -- it's not failing!
#				it { should_not have_selector('div.alert.alert-success') }				
# 				why this no work? 
				it "doesn't delete user" do
					expect { delete user_path(admin) }.not_to change(User, :count).by(-1)
				end
			end
		end

	end
end
