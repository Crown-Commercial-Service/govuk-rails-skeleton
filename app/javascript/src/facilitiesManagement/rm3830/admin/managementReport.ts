import { FileUploadProgressWithoutBar, type StateToProgressWithoutProgressBar } from '../../uploadProgress'

const managementReportStateToProgress: StateToProgressWithoutProgressBar = {
  generating_csv: {
    wait: 15000,
    isFinished: false
  },
  completed: {
    wait: 0,
    isFinished: true
  }
}

const initManagementReport = (): void => {
  if ($('#management-report-status').length && $('.management-report-state-generating_csv').length) new FileUploadProgressWithoutBar(managementReportStateToProgress, 'generating_csv')
}

export default initManagementReport
