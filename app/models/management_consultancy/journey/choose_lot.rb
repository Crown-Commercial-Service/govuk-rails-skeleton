module ManagementConsultancy
  class Journey::ChooseLot
    include ::Journey::Step

    attribute :lot
    validates :lot, inclusion: {
      in: ['1', '2', '3', '4']
    }

    def next_step_class
      Journey::ChooseServices
    end
  end
end
