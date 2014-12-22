window.Checkout =

  selectListener: ->
    $('body').on('click', 'button.select', ->
      $this = $(this)
      target = $('#checkout-wrap')
      productId = $this.parent('.thumbnail').data('product-id')
      $('input[name="product_id"]').val(productId)

      $('td.quantity').html($this.siblings().children('.quantitys').text())
      $('td.price').html($this.siblings().children('.price').text())
      $('td.shipping-price').html($this.siblings().children('.shipping-price').text())
      $('td.total-price').html($this.siblings().children('.total-price').text())
      $('#promo_code').val(null)
      $('#promo_code').prop('disabled', false)
      $('#promo-apply').prop('disabled', false)
      $('#accessory_pack').attr('checked', false)
      $('#intl_shipping').attr('checked', false)
      $('#engraving').attr('checked', false)
      $('#color').val('steel')
      $('tr.promo-row').addClass('hidden')
      $('tr.international-shipping').addClass('hidden')
      $('tr.custom-engraving').addClass('hidden')
      $('tr.accessory-pack').addClass('hidden')
      $('tr.color-black').addClass('hidden')
      $('tr.color-rose-gold').addClass('hidden')
      $('tr.color-sky-blue').addClass('hidden')
      $('.response').html(null)
      $("html,body").animate
        scrollTop: target.offset().top
      , 1000
      $('button.select').css('background-color','#2980b9')
      $(this).css('background-color','#16a085')
      $('#fbshare').val("0")
      $('#twshare').val("0")
    )

  promoCodeListener: ->
    $('body').on('click', '#promo-apply', ->
      $.ajax({
        url: 'orders/promo_code',
        type: 'GET',
        beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')),
        dataType: 'json',
        data: {
          code: $('#promo_code').val(),
          product_id: $('#product_id').val(),
          fbshare: $('#fbshare').val(),
          twshare: $('#twshare').val(),
          color: $('#color').val(),
          engraving: $('#engraving').prop('checked'),
          accessory_pack: $('#accessory_pack').prop('checked')
          intl_shipping: $('#intl_shipping').prop('checked')
        }
      })
      .success((data) ->
        $('td.total-price').html('$' + data.price.toFixed(2))
        $('.form-group.row').removeClass('has-error')
        $('.response.promo').removeClass('error').addClass('success')
        $('.response.promo').html(data.message)
        $('td.promo-code').html(data.code)
        $('td.discount').html('- ' + data.discount)
        $('tr.promo-row').removeClass('hidden')
        $('#promo_code').prop('disabled', true);
        $('#promo-apply').prop('disabled', true);
      )
      .error((data) ->
        $('.form-group.row').addClass('has-error')
        $('.response.promo').removeClass('success').addClass('error')
        $('.response.promo').html(data.responseJSON.error)
      )
      false
    )

  socialFBShare: ->
    $('body').on('click', '#fbshare', (e)->
      link =  ($('#fbshare1').attr('href'))
      e.preventDefault()
      if $('#fbshare').val() == '0'
        $('#fbshare').val(1)
        fbprice = parseFloat($('td.total-price').text().replace('$', ''))
        $('td.total-price').html('$' + (fbprice - 1).toFixed(2))
      window.open(link, '_blank')
    )

  socialTWShare: ->
    $('body').on('click', '#twshare', (e)->
      link =  ($('#twshare1').attr('href'))
      e.preventDefault()
      if $('#twshare').val() == '0'
        $('#twshare').val(1)
        twprice = parseFloat($('td.total-price').text().replace('$', ''))
        $('td.total-price').html('$' + (twprice - 1).toFixed(2))
      window.open(link, '_blank')

    )

  customizationListener: ->
    $('select#color, input#engraving, input#accessory_pack, input#intl_shipping').bind('change', ->
      $.ajax({
        url: '/bravo/orders/price',
        type: 'GET',
        beforeSend: (xhr) -> xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content')),
        dataType: 'json',
        data: {
          code: $('#promo_code').val(),
          product_id: $('#product_id').val(),
          fbshare: $('#fbshare').val(),
          twshare: $('#twshare').val(),

          color: $('#color').val(),
          engraving: $('#engraving').prop('checked'),
          accessory_pack: $('#accessory_pack').prop('checked'),
          intl_shipping: $('#intl_shipping').prop('checked')
        }
      })
      .success((data) ->
        $('td.total-price').html('$' + data.price.toFixed(2))
      )
      .error(
        # Swallow It
      )
    )

  shippingListener: ->
    $('input#intl_shipping').bind('change', ->
      if $('#intl_shipping').prop('checked')
        price = parseFloat($('td.total-price').text().replace('$', ''))
        $('td.total-price').html('$' + (price + 10).toFixed(2))
      else
        price = parseFloat($('td.total-price').text().replace('$', ''))
        $('td.total-price').html('$' + (price - 10).toFixed(2))
    )

  cartExtras: ->
    $('input#intl_shipping').bind('change', ->
      if $('#intl_shipping').prop('checked')
        $('tr.international-shipping').removeClass('hidden')
      else
        $('tr.international-shipping').addClass('hidden')
    )
    $('input#engraving').bind('change', ->
      if $('#engraving').prop('checked')
        $('tr.custom-engraving').removeClass('hidden')
      else
        $('tr.custom-engraving').addClass('hidden')
    )
    $('input#accessory_pack').bind('change', ->
      if $('#accessory_pack').prop('checked')
        $('tr.accessory-pack').removeClass('hidden')
      else
        $('tr.accessory-pack').addClass('hidden')
    )
    $('#color').bind('change', ->
      if $('#color').val() == 'rose gold' and $('#product_id').val() != "nil"
        $('tr.color-rose-gold').removeClass('hidden')
        $('tr.color-black').addClass('hidden')
        $('tr.color-sky-blue').addClass('hidden')
      else if $('#color').val() == 'black' and $('#product_id').val() != "nil"
        $('tr.color-rose-gold').addClass('hidden')
        $('tr.color-black').removeClass('hidden')
        $('tr.color-sky-blue').addClass('hidden')
      else if $('#color').val() == 'sky blue' and $('#product_id').val() != "nil"
        $('tr.color-rose-gold').addClass('hidden')
        $('tr.color-black').addClass('hidden')
        $('tr.color-sky-blue').removeClass('hidden')
      else
        $('tr.color-rose-gold').addClass('hidden')
        $('tr.color-black').addClass('hidden')
        $('tr.color-sky-blue').addClass('hidden')
    )

  checkoutListener: ->
    $('body').on('click','input#checkout', (e)->
      e.preventDefault()
      $('#promo_code').prop('disabled', false)
      $('#checkout').closest('form').submit()
    )
  shareNullify: ->

  init: ->
    this.selectListener()
    this.promoCodeListener()
    this.socialFBShare()
    this.socialTWShare()
    this.cartExtras()
    this.shippingListener()
    this.customizationListener() if $('form#new_bravo_order').length
    this.customizationListener() if $('form#new_buy_order').length
    this.checkoutListener()

Checkout.init() if $('#checkout-form').length
