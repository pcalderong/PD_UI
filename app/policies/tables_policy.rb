class TablesPolicy < ApplicationPolicy
  def show?
    user.admin?
  end
end
