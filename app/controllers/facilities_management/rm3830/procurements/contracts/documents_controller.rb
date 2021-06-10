module FacilitiesManagement
  module RM3830
    module Procurements
      module Contracts
        class DocumentsController < FacilitiesManagement::FrameworkController
          before_action :set_contract, except: :zip_contracts
          # If this document generation changes you must change it
          # app/helpers/facilities_management/rm3830/procurements/documents_procurement_helper.rb self.generate_doc
          def call_off_schedule
            @supplier = @contract.supplier
            @procurement = @contract.procurement
            @buyer_detail = @procurement.user.buyer_detail
            @invoice_contact_detail = @procurement.using_buyer_detail_for_invoice_details? ? @buyer_detail : @procurement.invoice_contact_detail
            @authorised_contact_detail = @procurement.using_buyer_detail_for_authorised_detail? ? @buyer_detail : @procurement.authorised_contact_detail
            @notice_contact_detail = @procurement.using_buyer_detail_for_notices_detail? ? @buyer_detail : @procurement.notices_contact_detail

            respond_to do |format|
              format.docx { headers['Content-Disposition'] = 'attachment; filename="Attachment 4 - Order Form and Call-Off Schedules (DA) v3.0.docx"' }
            end
          end

          def zip_contracts
            file_stream = FacilitiesManagement::RM3830::Procurements::DocumentsProcurementHelper.build_download_zip_file(params[:contract_id])
            send_data file_stream.read, filename: 'review_your_contract.zip', type: 'application/zip'
          end

          def call_off_schedule_2
            @procurement = @contract.procurement
            @pension_funds = @procurement.procurement_pension_funds

            respond_to do |format|
              format.docx { headers['Content-Disposition'] = 'attachment; filename="Call-Off Schedule 2 - Staff Transfer (DA) v3.0.docx"' }
            end
          end

          private

          def set_contract
            @contract = FacilitiesManagement::ProcurementSupplier.find(params[:contract_id])
          end

          protected

          def authorize_user
            @contract ||= FacilitiesManagement::ProcurementSupplier.find(params[:contract_id])
            authorize! :manage, @contract.procurement
          end
        end
      end
    end
  end
end
