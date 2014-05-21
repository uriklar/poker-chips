# == Schema Information
#
# Table name: orders
#
#  id             :integer          not null, primary key
#  description    :string(255)
#  amount         :integer
#  state          :string(255)      default("pending")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  booking_id     :integer
#  custom_percent :decimal(, )
#

class Order < ActiveRecord::Base
	include AASM
  attr_accessible :amount, :description, :state, :card_number, :expiry_month, :expiry_year, :verification_code,
  							  :cardholder_fname, :cardholder_lname
  attr_accessor :card_number, :expiry_month, :expiry_year, :verification_code, :cardholder_fname, :cardholder_lname

  has_many :transactions, class_name: 'OrderTransaction', dependent: :destroy
	aasm_column :state
	aasm do
		state :pending, initial: true
		state :authorized
		state :paid
		state :payment_declined

		event :payment_authorized do
		transitions :from => :pending,
								:to => :authorized
		transitions :from => :payment_declined,
								:to => :authorized
		end

		event :payment_captured do
		transitions :from => :authorized,
								:to => :paid
		end

		event :transaction_declined do
		transitions :from => :pending,
								:to => :payment_declined
		transitions :from => :payment_declined,
								:to => :payment_declined
		transitions :from => :authorized,
								:to => :authorized
		end
	end

	def authorize_payment(credit_card, options = {})
		options[:order_id] = number
		transaction do
			authorization = OrderTransaction.authorize(amount,credit_card, options)
			transactions.push(authorization)
			if authorization.success?
				payment_authorized!
			else
				transaction_declined!
			end
		authorization
		end
	end

	def authorization_reference
		if authorization = transactions.find_by_action_and_success('authorization', true, :order => 'id ASC')
			authorization.reference
		end
	end


	def capture_payment(options = {})
		transaction do
			capture = OrderTransaction.capture(amount, authorization_reference, options)
			transactions.push(capture)
			if capture.success?
				payment_captured!
			else
				transaction_declined!
			end
			capture
		end
	end

	def number
		Random.new.bytes(10).bytes.join[0,10]
	end

	def invoice_total
		p = custom_percent || booking.commision_percent
		amount * p
	end

end
