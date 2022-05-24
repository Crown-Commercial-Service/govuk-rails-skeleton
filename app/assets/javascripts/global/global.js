function ifChecked(sWrap, h) {
    let howmany;
  
    if (sWrap === false) {
      howmany = 0;
    } else {
      howmany = sWrap.find('.govuk-checkboxes__input:checked').length;
    }
  
    if (howmany > 0) {
      const txt = h.data('txt');
      h.find('.ccs-filter-no').text(howmany).end().find('.ccs-filter-txt')
        .text(txt)
        .end()
        .addClass('ccs-hint--show');
    } else {
      h.removeClass('ccs-hint--show').find('.ccs-filter-no').empty().end()
        .find('.ccs-filter-txt')
        .empty();
    }
  }
  
  function whenChecked(sWrap, h) {
    const allcheckbxs = sWrap.find('.govuk-checkboxes__input');
  
    allcheckbxs.on('change', () => {
      ifChecked(sWrap, h);
    });
  }
  
  function initSearchResults(id) {
    const accord = id.find('.ccs-at-checkbox-accordian');
  
    accord.each(function (index) {
      const shopWrap = $(this);
  
      const hint = shopWrap.find('.ccs-govuk-hint--selected');
      if (hint.length) {
        ifChecked(shopWrap, hint);
        whenChecked(shopWrap, hint);
      }
  
      const link = $(this).find('.ccs-at-btn-toggle');
  
      link.attr('aria-expanded', 'false').on('click', function (e) {
        e.preventDefault();
  
        $(this).attr('aria-expanded', $(this).attr('aria-expanded') === 'true' ? 'false' : 'true')
          .find('span').text((i, text) => (text === 'Hide' ? ' Show' : ' Hide'));
  
        if (shopWrap.hasClass('show')) {
          shopWrap.removeClass('show');
        } else {
          shopWrap.addClass('show');
        }
      });
    });
  
    const checkboxs = accord.find('.govuk-checkboxes__input');
  
    checkboxs.keypress(function (e) {
      if ((e.keyCode ? e.keyCode : e.which) == 13) {
        $(this).trigger('click');
      }
    });
  
    $('#ccs-clear-filters').on('click', (e) => {
      e.preventDefault();
      checkboxs.prop('checked', false);
  
      const hint = id.find('.ccs-govuk-hint--selected');
      if (hint.length) {
        ifChecked(false, hint);
      }
    });
  }
  
  function updateTitle(i, v, b) {
    const span = b.find('span:first-child');
  
    if (v === true) {
      span.text(i);
      $('#removeAll').removeClass('ccs-remove');
      headerTxt(b, true);
    } else {
      span.empty();
      $('#removeAll').addClass('ccs-remove');
      headerTxt(b, false);
    }
  }
  
  function headerTxt(header, t) {
    let tx;
    if (t === true) {
      tx = header.data('txt01');
    } else {
      tx = header.data('txt02');
    }
    header.find('span:last-child').text(tx);
  }
  
  function updateList(govb, id, basket) {
    let i = '';
    let thelist = '';
    let $this;
    const list = id.find('ul');
    const thecheckboxes = govb.find('.govuk-checkboxes__item').not('.ccs-select-all').find('.govuk-checkboxes__input:checked');
  
    list.find('.ccs-removethis').remove();
  
    if (thecheckboxes.length) {
      thecheckboxes.each(function (index) {
        $this = $(this);
        thelist = `${thelist}<li class="ccs-removethis"><span>${$this.next('label').text()}</span> <a href="#" data-id="${$this.attr('id')}">Remove</a></li>`;
        i = index + 1;
      });
      updateTitle(i, true, basket);
    } else {
      updateTitle(i, false, basket);
    }
  
    list.append(thelist).find('a').on('click', function (e) {
      e.preventDefault();
      const thisbox = $(`#${$(this).data('id')}`);
  
      $(this).parent().remove();
      thisbox.prop('checked', false);
      i -= 1;
      if (i > 0) {
        updateTitle(i, true, basket);
      } else {
        updateTitle(i, false, basket);
      }
  
      const theparent = thisbox.parents('.govuk-checkboxes').find('.ccs-select-all').find('.govuk-checkboxes__input:checked');
      if (theparent.length) {
        theparent.prop('checked', false);
      }
    });
  
    $('#removeAll').on('click', function (e) {
      e.preventDefault();
      list.find('.ccs-removethis').remove();
      govb.find('.govuk-checkboxes__input:checked').prop('checked', false);
      headerTxt(basket, false);
      $(this).addClass('ccs-remove').siblings().find('span:first-child')
        .empty();
    });
  }
  
  function initStepByStepNav() {
    const $element = $('#step-by-step-navigation');
    const stepByStepNavigation = new window.GOVUKFrontend.Modules.Gemstepnav($element.get(0))
    stepByStepNavigation.init();
  }
  
  function initCustomFnc() {
    const filt = $('#ccs-at-results-filters');
    if (filt.length) {
      initSearchResults(filt);
    }
  
    if ($('#step-by-step-navigation').length) {
      initStepByStepNav();
    }
  }
  
$(() => {
    initCustomFnc();
  });
  