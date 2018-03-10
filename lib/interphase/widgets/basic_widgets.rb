# frozen_string_literal: true

require 'gtk2'

module Interphase
  # A basic GTK widget wrapper.
  class Widget
    attr_accessor :gtk_instance, :parent, :name

    # Creates a new widget.
    # +gtk_instance+:: The GTK widget instance this is wrapping.
    # +name:+:: This widgets name, allowing it to be referred to after being
    #           created.
    def initialize(gtk_instance, **options, &block)
      @gtk_instance = gtk_instance
      @parent = nil
      @name = options[:name]

      instance_eval(&block) if block_given?
    end

    # Requests that this widget is resized. Note that this is a method, rather
    # than a 'size=' setter, because the request is not guaranteed, and indeed
    # in many cases will not. Only some containers allow their child widgets
    # to be resized.
    def size(width, height)
      gtk_instance.set_size_request(width, height)
    end

    # Shows this widget.
    def show
      gtk_instance.show
    end

    # Associates a block with a signal. The block is invoked whenever the
    # signal occurs.
    # +name+:: The name of the signal.
    def on(name, &block)
      gtk_instance.signal_connect(name, &block)
    end

    # Destroy this widget.
    def destroy
      gtk_instance.destroy
    end

    # Respond to lookups by name.
    # TODO IMPLEMENT RESPONDS_TO
    def method_missing(requested, *args, &block)
      # If any arguments or a block have been given, then this isn't an attr
      if !args.empty? || block_given?
        super
        return
      end

      return self if requested.to_s == name

      super
    end

    def respond_to_missing?
      true
    end
  end

  # A widget which may contain other widgets.
  class Container < Widget
    attr_accessor :children

    # Add a widget as a child of this one.
    # Accepts a block which is executed on the child.
    # +child+:: The new child widget.
    # +should_add+:: (Optional) Whether to actually add the element, or just to
    #                register it as added by adding it to +children+. You
    #                probably shouldn't change this.
    def add(child, should_add = true, &block)
      child.instance_eval(&block) if block_given?

      raise 'Widget already has a parent' unless child.parent.nil?

      gtk_instance.add(child.gtk_instance) if should_add
      child.parent = self

      # Ensure a children array exists, and add the new child to it
      @children ||= []
      children << child
    end

    # Show this widget and all of its children.
    def show_all
      gtk_instance.show_all
    end

    # Allows child named widgets to be looked up like an attribute.
    # TODO IMPLEMENT RESPONDS_TO
    def method_missing(requested, *args, &block)
      (children || []).each do |child|
        # An exception simply means that wasn't the child we were looking for
        begin
          return child.send(requested)
        rescue StandardError
          next
        end
      end

      super
    end

    def respond_to_missing?(*)
      true
    end
  end
end
