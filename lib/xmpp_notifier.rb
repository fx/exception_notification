require 'pathname'
require 'xmpp4r/client'
require 'xmpp4r/roster'

# Copyright (c) 2009 Marian Rudzynski
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
class XmppNotifier
	@@sender_account = []
	cattr_accessor :sender_account

	@@exception_recipients = []
	cattr_accessor :exception_recipients

	@@message_prefix = "[ERROR] "
	cattr_accessor :message_prefix

	@@sections = %w(request session environment backtrace)
	cattr_accessor :sections

	@@client = nil
	cattr_accessor :client

	@@roster = nil
	cattr_accessor :roster

	class << self
		def reloadable?() 
			false
		end

		def connect
			if !client
				jid = Jabber::JID::new(sender_account[0])

				@@client = Jabber::Client.new(jid)
				@@client.connect
				@@client.auth(sender_account[1])
				
				@@client.send(Jabber::Presence.new.set_type(:available))
				
				@@roster = Jabber::Roster::Helper.new(@@client)
				@@roster.add_subscription_request_callback do |item, pres|
					@@roster.accept_subscription(pres.from)
				end
			end
		end

		def send(body)
			message = Jabber::Message.new
			message.set_type(:normal)
			message.set_id('1')
			message.set_subject('')

			message.body = body

			exception_recipients.each {|recipient|
				message.to = recipient
				@@client.send(message)
			}
		end

		def exception_notification(exception, controller, request, data={})
			return false if sender_account.empty? || exception_recipients.empty?
			self.connect if !@@client
			if @@client
				body = "#{message_prefix}#{controller.controller_name}##{controller.action_name} (#{exception.class}) #{exception.message.inspect} in #{exception.backtrace.first.inspect}\n"
				send(body)
			end

		end
	end
end
