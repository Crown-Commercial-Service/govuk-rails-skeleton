import { FileUploadProgressWithBar, type StateToProgressWithProgressBar } from '../../uploadProgress'

const adminStateToProgress: StateToProgressWithProgressBar = {
  not_started: {
    progress: 10,
    wait: 500,
    state: 'progress-0'
  },
  in_progress: {
    progress: 10,
    wait: 500,
    state: 'progress-0'
  },
  checking_files: {
    progress: 30,
    wait: 500,
    state: 'progress-1'
  },
  processing_files: {
    progress: 50,
    wait: 500,
    state: 'progress-2'
  },
  checking_processed_data: {
    progress: 50,
    wait: 500,
    state: 'progress-2'
  },
  publishing_data: {
    progress: 70,
    wait: 500,
    state: 'progress-3'
  },
  published: {
    progress: 100,
    wait: 500,
    state: 'progress-4',
    colourClass: 'ccs-progress-bar--succeed',
    isFinished: true
  },
  failed: {
    progress: 100,
    wait: 500,
    state: 'progress-4',
    colourClass: 'ccs-progress-bar--fail',
    isFinished: true
  }
}

const initAdminUpload = (): void => {
  if ($('#admin-import').length) new FileUploadProgressWithBar(adminStateToProgress, 'in_progress')
}

export default initAdminUpload
