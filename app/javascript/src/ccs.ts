import initCheckboxAccordion from './shared/checkboxAccordion'
import initChooseServicesForBuilding from './facilitiesManagement/procurements/chooseServicesForBuilding'
import initContactDetailsInStorage from './facilitiesManagement/contactDetailsInStorage'
import initCookieBanner from './shared/cookieBanner'
import initDetailsLinks from './facilitiesManagement/detailsLinks'
import initFilterTable from './facilitiesManagement/filterTable'
import initFindAddress from './facilitiesManagement/findAddress'
import initGoogleAnalyticsDataLayer from './shared/googleAnalyticsDataLayer'
import initLimitInputToInteger from './facilitiesManagement/integerInput'
import initManagementReport from './facilitiesManagement/rm3830/admin/managementReport'
import initNumberWithCommas from './facilitiesManagement/numberWithCommas'
import initRM3830AdminAdminUpload from './facilitiesManagement/rm3830/admin/adminUploadProgress'
import initSelectRegion from './facilitiesManagement/procurements/selectRegion'
import initStepByStepNav from './shared/stepByStepNav'
import initSupplierDataSnapshot from './facilitiesManagement/rm6232/admin/supplierDataSnapshot'

const initAll = () => {
  // Facilities Management - Procurements TS
  initChooseServicesForBuilding()
  initSelectRegion()

  // Facilities Management - RM3830 - Admin TS
  initRM3830AdminAdminUpload()
  initManagementReport()

  // Facilities Management - RM6232 - Admin TS
  initSupplierDataSnapshot()

  // Facilities Management TS
  initContactDetailsInStorage()
  initDetailsLinks()
  initFilterTable()
  initFindAddress()
  initLimitInputToInteger()
  initNumberWithCommas()

  // Shared TS
  initCheckboxAccordion()
  initCookieBanner()
  initGoogleAnalyticsDataLayer()
  initStepByStepNav()
}

export { initAll }
