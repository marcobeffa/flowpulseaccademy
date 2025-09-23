module Generaimpresa
  class ListsController < ApplicationController
    before_action :superadmin
    before_action :set_list, except: [ :new, :create, :index ]
    layout "dashboard"
    def index
      @lists = List.order(updated_at: :desc)
      @item_counts = Item.where(list_id: @lists).group(:list_id).count
      @list = List.new            # <-- AGGIUNGI QUESTO
    end



    def new
      @list = List.new
    end

    def create
      @list = List.new(list_params)
      if @list.save
        redirect_to order_generaimpresa_list_path(@list), notice: "Lista creata"
      else
        render :new, status: :unprocessable_entity
      end
    end

    # GET/PATCH /generaimpresa/lists/:id/order
    def order
      if request.get?
        respond_to do |format|
          format.html
          format.json { render json: { nodes: serialize_items(@list) } }
        end
      else
        nodes = params.require(:nodes)
        delete_missing = ActiveModel::Type::Boolean.new.cast(params[:delete_missing])
        ReorderList.call(@list, nodes, delete_missing: delete_missing)
        head :no_content
      end
    end
    def show
      @nodes = serialize_items(@list)   # <-- array [{id:, title:, children:[...]}]
      respond_to do |format|
        format.html # renderizza la view
        format.json { render json: { id: @list.id, name: @list.name, nodes: @nodes } }
      end
    end



    def edit
    end

    def update
      if @list.update(list_params)
        redirect_to [ :generaimpresa, @list ], notice: "Lista aggiornata con successo."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @list.destroy
      redirect_to generaimpresa_lists_path, notice: "Lista eliminata con successo."
    end

    private


    def superadmin
      redirect_to root_path, alert: "Accesso negato" unless Current.user.superadmin?
    end

    def set_list
      @list = List.find(params[:id])
    end

    def list_params
      params.require(:list).permit(:name)
    end

    # def serialize_items(list)
    #   items = list.items.order(:ancestry, :position, :id).to_a
    #   by_id = items.index_by(&:id)
    #   roots = []
    #   items.each { |it| it.define_singleton_method(:buf) { @buf ||= [] } }
    #   items.each { |it| it.parent_id ? by_id[it.parent_id]&.buf << it : roots << it }
    #   to_node = ->(it) { { id: it.id, title: it.title, children: it.buf.sort_by { |c| [ c.position || 0, c.id ] }.map { |c| to_node.call(c) } } }
    #   roots.sort_by { |r| [ r.position || 0, r.id ] }.map { |r| to_node.call(r) }
    # end
    def serialize_items(list)
      # Carica solo le colonne necessarie
      items = list.items.select(:id, :title, :ancestry, :position).to_a

      # Mappa figli per parent_id (usiamo il metodo virtuale di Ancestry)
      children_map = Hash.new { |h, k| h[k] = [] }
      roots = []

      items.each do |it|
        if (pid = it.parent_id)
          # se il parent non esiste nei items, tratteremo come root più sotto
          children_map[pid] << it
        else
          roots << it
        end
      end

      # Sposta eventuali orfani (parent non presente) tra le radici
      children_map.keys.each do |pid|
        next if items.any? { |i| i.id == pid }
        roots.concat(children_map.delete(pid))
      end

      to_node = lambda do |it|
        kids = (children_map[it.id] || []).sort_by { |c| [ c.position || 0, c.id ] }
        { id: it.id, title: it.title.to_s, children: kids.map { |k| to_node.call(k) } }
      end

      roots.sort_by { |r| [ r.position || 0, r.id ] }.map { |r| to_node.call(r) }
    end

    # def serialize_items(list)
    #   items = list.items.order(:ancestry, :position, :id).to_a
    #   by_id = items.index_by(&:id)

    #   build_tree = ->(parent) do
    #     children = items.select { |i| i.parent_id == parent&.id }
    #     children.map do |it|
    #       {
    #         id: it.id,
    #         title: it.title,
    #         children: build_tree.call(it)
    #       }
    #     end
    #   end

    #   build_tree.call(nil)
    # end
  end
end
