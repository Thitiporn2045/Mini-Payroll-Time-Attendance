module ApplicationHelper
  def employee_form_return_path(employee = nil)
    if params[:return_to] == "employee" && employee.present?
      employee_path(employee, month: params[:month], status: params[:status])
    else
      employees_path(employee_query: params[:employee_query], position: params[:position])
    end
  end
end
