type PostcodeResult = {
  valid: false
  input: string
  fullPostcode?: never
} | {
  valid: true
  input: string
  fullPostcode: string
}

interface ErrorMessages {
  invalid: string
}

interface AddressResult {
  summary_line: string
  address_line_1: string
  address_line_2: string
  address_town: string
  address_postcode: string
}

interface RegionResult {
  code: string
  region: string
}

interface ResultTextPromptOptions {
  textSingle: string
  textPlural: string
}

interface AddressElements {
  summaryLine: string
  addressLine1: string
  addressLine2: string
  addressTown: string
  addressPostcode: string
}

interface RegionElements {
  addressRegion: string
  addressRegionCode: string
}

interface HiddenAddressInputs {
  addressLine1: JQuery<HTMLInputElement>
  addressLine2: JQuery<HTMLInputElement>
  addressTown: JQuery<HTMLInputElement>
  addressCounty: JQuery<HTMLInputElement>
}

interface HiddenRegionInputs {
  addressRegion: JQuery<HTMLInputElement>
  addressRegionCode: JQuery<HTMLInputElement>
}

interface FindAddressSelectSectionInterface {
  processResult: (results: AddressResult[] | RegionResult[]) => void
  clearSelection: () => void
}

interface FindAddressTextSectionInterface {
  clearSelectedItems: () => void
}

interface PostcodeSearchInterface {
  getPostcode: () => string
}

interface PostcodeChangeInterface {
  setPostcode: (postcode: string) => void
}

interface SelectAnAddressInterface {
  getAddressElements: () => AddressElements
}

interface SelectedAddressInterface {
  populateSelectedAddress: (addressElements: AddressElements) => void
}

interface SelectARegionInterface {
  getRegionElements: () => RegionElements
  isOneResult: () => boolean
  selectOnlyRegion: () => void
  resetSelectedRegion: () => void
}

interface SelectedRegionInterface {
  populateSelectedRegion: (regionElements: RegionElements) => void
  toggleChangeLinkVisibility: (isShown: boolean) => void
}

interface FindAddressInterface {
  findAddressFromPostcode: () => void
  changePostcode: () => void
  addressesFound: () => void
  addressSelected: () => void
  changeAddress: () => void
  regionsFound: () => void
  regionSelected: () => void
  changeRegion: () => void
}

const callAPI = (module: FindAddressSelectSection, url: string): void => {
  let result: AddressResult[] | RegionResult[]

  $.ajax({
    type: 'GET',
    url: encodeURI(url),
    dataType: 'json',
    success (data) {
      result = data.result ?? []
    },
    error () {
      result = []
    },
    complete () {
      module.processResult(result)
    }
  }).catch(() => {
    module.processResult([])
  })
}

abstract class FindAddressSection {
  protected findAddress
  protected $section: JQuery<HTMLElement>

  constructor (findAddress: FindAddress, $section: JQuery<HTMLElement>) {
    this.findAddress = findAddress
    this.$section = $section
  }

  toggleSectionVisibility = (isShown: boolean): void => {
    let tabindex

    if (isShown) {
      this.$section.removeClass('govuk-visually-hidden')
      tabindex = 0
    } else {
      this.$section.addClass('govuk-visually-hidden')
      tabindex = -1
    }

    if (this.$section.attr('tabindex')) this.$section.attr('tabIndex', tabindex)
    this.$section.find('[tabindex]').attr('tabIndex', tabindex)
  }

  abstract focus (): JQuery<HTMLElement>
  protected _focus = ($element: JQuery<HTMLElement>): JQuery<HTMLElement> => $element.trigger('focus')
}

abstract class FindAddressInputSection extends FindAddressSection {
  protected $input: JQuery<HTMLInputElement>
  protected inputErrorClass: string
  protected $errorMessage?: JQuery<HTMLElement>
  protected errorMessageID = `${this.$section.data('propertyname') as string ?? ''}-error`
  protected $formGroup: JQuery<HTMLElement>
  protected errorMessageText?: string

  constructor (findAddress: FindAddress, $section: JQuery<HTMLElement>, $input: JQuery<HTMLInputElement>, inputType: string) {
    super(findAddress, $section)

    this.$input = $input
    this.inputErrorClass = `govuk-${inputType}--error`
    this.$formGroup = $input.parent('.govuk-form-group')
    if ($input.data('error-messages') !== undefined) this.errorMessageText = ($input.data('error-messages') as ErrorMessages).invalid

    this.setErrorMessageElement()
  }

  private readonly setErrorMessageElement = (): void => {
    this.$errorMessage = $(`#${this.errorMessageID}`)
  }

  protected showError = (): void => {
    const errorMessageHTML = `<span id="${this.errorMessageID}" class="govuk-error-message">${this.errorMessageText ?? ''}</span>`

    this.$input.before(errorMessageHTML)
    this.setErrorMessageElement()

    this.$formGroup.addClass('govuk-form-group--error')
    this.$input.addClass(this.inputErrorClass)
  }

  protected clearError = (): void => {
    if (this.$errorMessage !== undefined) {
      this.$errorMessage.remove()
      delete this.$errorMessage
    }

    this.$formGroup.removeClass('govuk-form-group--error')
    this.$input.removeClass(this.inputErrorClass)
  }
}

abstract class FindAddressSelectSection extends FindAddressInputSection implements FindAddressSelectSectionInterface {
  protected resultTextPromptOptions: ResultTextPromptOptions = this.$input.data() as ResultTextPromptOptions
  protected $selectedItem: JQuery<HTMLOptionElement> = $(this.$input.find('option:selected')) as JQuery<HTMLOptionElement>
  private readonly findAddresCallback: () => void
  private readonly resultProcessedCallback: () => void

  constructor (findAddress: FindAddress, $section: JQuery<HTMLElement>, $input: JQuery<HTMLInputElement>, inputType: string, findAddresCallback: () => void, resultProcessedCallback: () => void) {
    super(findAddress, $section, $input, inputType)

    this.findAddresCallback = findAddresCallback
    this.resultProcessedCallback = resultProcessedCallback

    this.setEventListener()
  }

  protected abstract createOption: (result: AddressResult | RegionResult) => string

  private readonly setEventListener = (): void => {
    this.$input.on('change', this.selectItem)
  }

  protected getPromptText = (resultsLength: number): string => `${resultsLength} ${resultsLength === 1 ? this.resultTextPromptOptions.textSingle : this.resultTextPromptOptions.textPlural}`

  protected getOptions = (results: AddressResult[] | RegionResult[]): string[] => {
    return [
      `<option value>${this.getPromptText(results.length)}</option>`,
      ...results.map((result: AddressResult | RegionResult): string => this.createOption(result))
    ]
  }

  protected selectItem = (): void => {
    const $selectedItem: JQuery<HTMLOptionElement> = $(this.$input.find('option:selected')) as JQuery<HTMLOptionElement>

    if ($selectedItem.val() === '') return

    this.itemSelected($selectedItem)
  }

  protected itemSelected = ($selectedItem: JQuery<HTMLOptionElement>): void => {
    this.clearError()

    this.$selectedItem = $selectedItem

    this.findAddresCallback()
  }

  processResult = (results: AddressResult[] | RegionResult[]): void => {
    this.clearSelection()

    this.getOptions(results).forEach((option: string) => this.$input.append(option))

    this.resultProcessedCallback()
  }

  clearSelection = (): void => {
    this.clearError()

    this.$input.empty()
  }

  focus = (): JQuery<HTMLElement> => this._focus(this.$input)
}

abstract class FindAddressTextSection<HiddenInputsType> extends FindAddressSection implements FindAddressTextSectionInterface {
  protected $sectionText: JQuery<HTMLElement>
  protected $changeSectionLink: JQuery<HTMLElement>
  protected abstract hiddenInputs: Record<keyof HiddenInputsType, JQuery<HTMLInputElement>>

  constructor (findAddress: FindAddress, $section: JQuery<HTMLElement>, $sectionText: JQuery<HTMLElement>, $changeSectionLink: JQuery<HTMLElement>, findAddresCallback: () => void) {
    super(findAddress, $section)

    this.$sectionText = $sectionText
    this.$changeSectionLink = $changeSectionLink

    this.setEventListener(findAddresCallback)
  }

  private readonly setEventListener = (findAddresCallback: () => void): void => {
    this.$changeSectionLink.on('click', (event: JQuery.ClickEvent) => {
      event.preventDefault()

      this.clearSelectedItems()

      findAddresCallback()
    })
  }

  clearSelectedItems = (): void => {
    this.$sectionText.text('')

    Object.entries<JQuery<HTMLInputElement>>(this.hiddenInputs).forEach(([, $hiddenInput]) => $hiddenInput.val(''))
  }

  focus = (): JQuery<HTMLElement> => this._focus(this.$changeSectionLink)
}

class PostcodeSearch extends FindAddressInputSection implements PostcodeSearchInterface {
  private readonly $findAddressButton: JQuery<HTMLButtonElement> = $('#find-address-button')
  private postcodeValue = String(this.$input.val() ?? '')

  constructor (findAddress: FindAddress) {
    super(
      findAddress,
      $('#postcode-search'),
      $('.postcode-entry'),
      'input'
    )

    this.setEventListener()
  }

  private readonly setEventListener = (): void => {
    this.$findAddressButton.on('click', (event: JQuery.ClickEvent) => {
      event.preventDefault()

      this.clearError()

      const destructuredPostCode = this.destructurePostCode()

      if (destructuredPostCode.valid) {
        this.postcodeValue = destructuredPostCode.fullPostcode
        this.findAddress.findAddressFromPostcode()
      } else {
        this.showError()
      }
    })
  }

  private destructurePostCode (): PostcodeResult {
    const input: string = String(this.$input.val() ?? '').trim().toUpperCase()
    const regEx = /^(([A-Z][A-Z]{0,1})([0-9][A-Z0-9]{0,1})) {0,}(([0-9])([A-Z]{2}))$/i
    const matches: RegExpMatchArray | null = input.match(regEx)

    let result: PostcodeResult = { valid: false, input }

    if (matches !== null) {
      result = {
        ...result,
        valid: true,
        fullPostcode: `${matches[1]} ${matches[4]}`
      }
    }

    return result
  }

  getPostcode = (): string => this.postcodeValue

  focus = (): JQuery<HTMLElement> => this._focus(this.$input)
}

class PostcodeChange extends FindAddressSection implements PostcodeChangeInterface {
  private readonly $postcodeOnView: JQuery<HTMLElement> = $('#postcode-on-view')
  private readonly $changePostcodeLink: JQuery<HTMLAnchorElement> = $('#change-input-1')

  constructor (findAddress: FindAddress) {
    super(findAddress, $('#postcode-change'))

    this.setEventListener()
  }

  private readonly setEventListener = (): void => {
    this.$changePostcodeLink.on('click', (event: JQuery.ClickEvent) => {
      event.preventDefault()

      this.findAddress.changePostcode()
    })
  }

  setPostcode = (postcode: string): void => {
    this.$postcodeOnView.text(postcode)
  }

  focus = (): JQuery<HTMLElement> => this._focus(this.$changePostcodeLink)
}

class SelectAnAddress extends FindAddressSelectSection implements SelectAnAddressInterface {
  constructor (findAddress: FindAddress) {
    super(
      findAddress,
      $('#select-an-address'),
      $('#address-results-container'),
      'select',
      findAddress.addressSelected,
      findAddress.addressesFound
    )
  }

  protected createOption = (result: AddressResult | RegionResult): string => {
    const addressResult: AddressResult = result as AddressResult

    return `
      <option
        value="${addressResult.summary_line}"
        data-address-line1="${addressResult.address_line_1}"
        data-address-line2="${addressResult.address_line_2}"
        data-address-town="${addressResult.address_town}"
        data-address-postcode="${addressResult.address_postcode}"
      >${addressResult.summary_line}</option>
    `
  }

  getAddressElements = (): AddressElements => {
    return {
      summaryLine: String(this.$selectedItem.val() ?? ''),
      addressLine1: this.$selectedItem.data('addressLine1'),
      addressLine2: this.$selectedItem.data('addressLine2'),
      addressTown: this.$selectedItem.data('addressTown'),
      addressPostcode: this.$selectedItem.data('addressPostcode')
    }
  }
}

class SelectedAddress extends FindAddressTextSection<HiddenAddressInputs> implements SelectedAddressInterface {
  protected hiddenInputs: HiddenAddressInputs = {
    addressLine1: $('#address-line-1'),
    addressLine2: $('#address-line-2'),
    addressTown: $('#address-town'),
    addressCounty: $('address-county')
  }

  constructor (findAddress: FindAddress) {
    super(
      findAddress,
      $('#selected-address'),
      $('#address-text'),
      $('#change-input-2'),
      findAddress.changeAddress
    )
  }

  populateSelectedAddress = (addressElements: AddressElements): void => {
    this.$sectionText.text(`${addressElements.summaryLine} ${addressElements.addressPostcode}`)

    this.hiddenInputs.addressLine1.val(addressElements.addressLine1)
    this.hiddenInputs.addressLine2.val(addressElements.addressLine2)
    this.hiddenInputs.addressTown.val(addressElements.addressTown)
  }
}

class SelectARegion extends FindAddressSelectSection implements SelectARegionInterface {
  constructor (findAddress: FindAddress) {
    super(
      findAddress,
      $('#select-a-region'),
      $('#regions-results-container'),
      'select',
      findAddress.regionSelected,
      findAddress.regionsFound
    )
  }

  protected createOption = (result: AddressResult | RegionResult): string => {
    const regionResult: RegionResult = result as RegionResult

    return `
      <option
        value="${regionResult.code}"
        data-address-region="${regionResult.region}"
        data-address-region-code="${regionResult.code}"
      >${regionResult.region}</option>
    `
  }

  private readonly regionOptions = (): JQuery<HTMLOptionElement> => this.$input.find('option[value][value!=""]') as JQuery<HTMLOptionElement>

  getRegionElements = (): RegionElements => {
    return {
      addressRegion: this.$selectedItem.data('addressRegion'),
      addressRegionCode: this.$selectedItem.data('addressRegionCode')
    }
  }

  isOneResult = (): boolean => {
    return this.regionOptions().length === 1
  }

  selectOnlyRegion = (): void => {
    const $selectedRegion: JQuery<HTMLOptionElement> = this.regionOptions()

    $selectedRegion.prop('selected', true)

    this.itemSelected($selectedRegion)
  }

  resetSelectedRegion = (): void => {
    this.$selectedItem.prop('selected', false)
  }
}

class SelectedRegion extends FindAddressTextSection<HiddenRegionInputs> implements SelectedRegionInterface {
  protected hiddenInputs: HiddenRegionInputs = {
    addressRegion: $('#address-region'),
    addressRegionCode: $('#address-region-code')
  }

  constructor (findAddress: FindAddress) {
    super(
      findAddress,
      $('#selected-region'),
      $('#region-text'),
      $('#change-input-3'),
      findAddress.changeRegion
    )
  }

  populateSelectedRegion = (regionElements: RegionElements): void => {
    this.$sectionText.text(regionElements.addressRegion)

    this.hiddenInputs.addressRegion.val(regionElements.addressRegion)
    this.hiddenInputs.addressRegionCode.val(regionElements.addressRegionCode)
  }

  toggleChangeLinkVisibility = (isShown: boolean): void => {
    let tabindex

    if (isShown) {
      this.$changeSectionLink.removeClass('govuk-visually-hidden')
      tabindex = 0
    } else {
      this.$changeSectionLink.addClass('govuk-visually-hidden')
      tabindex = -1
    }

    this.$changeSectionLink.attr('tabIndex', tabindex)
  }
}

enum StateToView {
  postcodeSearch = 1,
  selectAddress = 2,
  addressSelectedOneRegion = 3,
  selectRegion = 4,
  regionSelected = 5
}

class FindAddress implements FindAddressInterface {
  private readonly postcodeSearch: PostcodeSearch
  private readonly postcodeChange: PostcodeChange
  private readonly selectAnAddress: SelectAnAddress
  private readonly selectedAddress: SelectedAddress
  private readonly selectARegion?: SelectARegion
  private readonly selectedRegion?: SelectedRegion

  constructor () {
    this.postcodeSearch = new PostcodeSearch(this)
    this.postcodeChange = new PostcodeChange(this)
    this.selectAnAddress = new SelectAnAddress(this)
    this.selectedAddress = new SelectedAddress(this)

    if ($('[data-module="find-region"]').length) {
      this.selectARegion = new SelectARegion(this)
      this.selectedRegion = new SelectedRegion(this)
    }
  }

  private readonly updateViewAndFocus = (state: number): void => {
    this.updateView(state)
    this.updateFocus(state)
  }

  private readonly updateView = (state: number): void => {
    this.postcodeSearch.toggleSectionVisibility(state === 1)
    this.postcodeChange.toggleSectionVisibility(state === 2)
    this.selectAnAddress.toggleSectionVisibility(state === 2)
    this.selectedAddress.toggleSectionVisibility(state >= 3)
    this.selectARegion?.toggleSectionVisibility(state === 4)
    this.selectedRegion?.toggleSectionVisibility(state === 3 || state === 5)
    this.selectedRegion?.toggleChangeLinkVisibility(state === 5)
  }

  private readonly updateFocus = (state: number): void => {
    switch (state) {
      case 1:
        this.postcodeSearch.focus()
        break
      case 2:
        this.selectAnAddress.focus()
        break
      case 3:
        this.selectAnAddress.focus()
        break
      case 4:
        this.selectARegion?.focus()
        break
      case 5:
        this.selectedRegion?.focus()
        break
      default:
        break
    }
  }

  findAddressFromPostcode = (): void => {
    const postcode = this.postcodeSearch.getPostcode()

    this.postcodeChange.setPostcode(this.postcodeSearch.getPostcode())
    callAPI(
      this.selectAnAddress,
      `/api/v2/postcodes/${postcode}`
    )
  }

  addressesFound = (): void => { this.updateViewAndFocus(StateToView.selectAddress) }

  changePostcode = (): void => {
    this.updateViewAndFocus(StateToView.postcodeSearch)
    this.selectAnAddress.clearSelection()
  }

  addressSelected = (): void => {
    this.selectedAddress.populateSelectedAddress(this.selectAnAddress.getAddressElements())

    if (this.selectARegion !== undefined) {
      const postcode = this.postcodeSearch.getPostcode()

      callAPI(
        this.selectARegion,
        `/api/v2/find-region-postcode/${postcode}`
      )
    } else {
      this.updateViewAndFocus(StateToView.addressSelectedOneRegion)
    }
  }

  regionsFound = (): void => {
    if (this.selectARegion !== undefined) {
      if (this.selectARegion.isOneResult()) {
        this.selectARegion.selectOnlyRegion()
        this.regionSelected()
      } else {
        this.updateViewAndFocus(StateToView.selectRegion)
      }
    }
  }

  changeAddress = (): void => {
    this.selectAnAddress.clearSelection()

    if (this.selectARegion !== undefined && this.selectedRegion !== undefined) {
      this.selectARegion.clearSelection()
      this.selectedRegion.clearSelectedItems()
    }

    this.updateViewAndFocus(StateToView.postcodeSearch)
  }

  regionSelected = (): void => {
    if (this.selectARegion !== undefined && this.selectedRegion !== undefined) {
      this.selectedRegion.populateSelectedRegion(this.selectARegion.getRegionElements())

      if (this.selectARegion.isOneResult()) {
        this.updateViewAndFocus(StateToView.addressSelectedOneRegion)
      } else {
        this.updateViewAndFocus(StateToView.regionSelected)
      }
    }
  }

  changeRegion = (): void => {
    if (this.selectARegion !== undefined && this.selectedRegion !== undefined) {
      this.selectARegion.resetSelectedRegion()
      this.selectedRegion.clearSelectedItems()

      this.updateViewAndFocus(StateToView.selectRegion)
    }
  }
}

const initFindAddress = (): void => {
  if ($('[data-module="find-address"]').length) new FindAddress()
}

export default initFindAddress
