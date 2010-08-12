Element.implement({
  classes: function() { return this.className.split(/\s+/) },
  updated: function(name) {
    if (name) Element.behaviour_builders_named.get(name).apply(this)
    else Element.behaviour_builders.each(function (fun) { fun.apply(this) }.bind(this))
    return this
  }
})
$extend(Element, {
  behaviour_builders: [],
  behaviour_builders_named: new Hash(),
  behaviour: function(a, b) {
    var fun = typeof(a) == 'function' ? a : b
    this.behaviour_builders.push(fun)
    if (typeof(a) == 'string') this.behaviour_builders_named.include(a, fun)
  }
})

// AlertBox

var Alertbox = new Element('div', { id: 'alert' })
$extend(Alertbox, {
  display: function(message, delay) {
    message = '' + message
    if (this.timeout) this.timeout = $clear(this.timeout)
    this.set('text', message).reposition().setStyle('visibility', 'visible')
    Alertbox.removeEvents('click').addEvent('click', function(e) {
      Alertbox.hide()
    })
    //this.get('tween', {onComplete: function() {}}).start('opacity', 0.7)
    if (!delay || delay > 0) this.timeout = this.hide.delay(delay || (2000 + message.length * 30), this)
  },
  wait: function() {
    this.display(_('wait'), -1)
  },
  reposition: function() {
    this.setStyles({
      top: this.ypos(),
      left: this.xpos()
    })
    return this
  },
	xpos: function() {
		return Math.round((document.documentElement.scrollLeft || document.body.scrollLeft) +
            (window.getWidth() - this.getWidth()) / 2);
	},
	ypos: function() {
		return Math.round((document.documentElement.scrollTop || document.body.scrollTop) +
            (window.getHeight() - this.getHeight()) / 2)
	},
  hide_unless_delayed: function() {
    if (!this.timeout && this.getStyle('opacity') > 0) this.hide()
  },
  hide: function() {
    //this.get('tween', {onComplete: function() {
      Alertbox.setStyle('visibility', 'hidden')
    //}}).start('opacity', 0)
  }
})

window.addEvent('domready', function() {
  // AlertBox
  Alertbox.inject(document.body)
  window._alert = window.alert
  window.alert = function(message) { Alertbox.display(message) }
})
    
transient = {
  div: null,
  open: function(what, style) {
    if (!this.div) {
      this.div = new Element('div', { id: 'transient' }).inject(document.body)
    }
    this.div.innerHTML = ''
    this.div.setStyles({
      width: (style && style.width ? style.width : '400')+'px',
      visibility: 'hidden' })

    if (typeof(what) == 'object') {
      if (!what.each) what = [what]
      what.each(function(i) { this.div.adopt(i) }.bind(this))
    } else {
      this.div.innerHTML = what
    }
    this.close_button = new Element('div', {'class': 'close-transient', 'text': 'X'})
    this.close_button.addEvent('click', function(e) {
      this.close()
    }.bind(this))
    this.close_button.inject(this.div)

    var size = this.div.getSize()
    this.div.setStyles({
      left: ((window.innerWidth - size.x) / 2) + 'px',
      top: ((window.innerHeight - size.y) / 2) + 'px',
      visibility: 'visible' })
  },
  close: function() {
    this.div.dispose()
    this.div = false
  },
  ajax: function(url) {
  }
}

window.addEvent('domready', function() { document.body.updated() })
window.addEvent('domready', function() {
  var link, next
  if (link = document.getElement('link.auto-post')) {
    new Request.JSON({
      url: link.get('href'),
      onSuccess: function(json) {
        jj = json
        $$('section.consultation').each(function (section) {
          var illness = section.get('data-illness-id')
          if (illness && json[illness]) {
            section.getElements('p.classification').dispose()
            var ul = new Element('ul', { 'class': 'classification' })
            json[illness].each(function(i) { new Element('li', { html: i }).inject(ul) })
            ul.inject(section) }})
        if (next = document.getElement('link[rel=next]')) window.location = next.href }}).post() }

  illnesses = document.getElements('form.diagnostic section.illness')
  if (illnesses[0]) {
    var form = document.getElement('form.diagnostic')
    var button = form.getElement('button[type=submit]').addClass('disabled')
    var first = null
    illnesses.each(function(i) {
      i.getElement('h2').addEvent('click', function() {
        alert_fill()
      })
      i.getElements('input[type=text]').each(function(input) {
        tr = input.getParent('tr')
        if (tr = tr.getPrevious()) {
          if (select = tr.getElement('select')) {
            select.addEvent('change', function(e) {
              if (this.selectedIndex < 2) {
                input.saved = input.value
                input.value = ''
                input.disabled = true
                input.fallback = new Element('input', {type: 'hidden', id: input.id, name: input.name, value: '0'})
                input.fallback.inject(input.getParent('tr'))
              } else {
                if (input.disabled == true)
                  input.value = input.saved
                input.disabled = false
                if (input.fallback) {
                  input.fallback.dispose()
                }
              }
            })
            select.fireEvent('change')
          }
        }
      })
    })

    var measurements_valid = true
    function open_illness(illness, scroll) {
      illness.getElement('h2').
        removeEvents('click').
        addEvent('click', function() { open_illness(illness) })
      illnesses.each(function(i) { i.addClass('closed') })
      illness.removeClass('closed')
      if (!illness.getElement('h2').getElement('ul'))
        validate_illness(illness)
      if (scroll != false) window.scrollTo(0, illness.getPosition().y)
    }
    function all_valid() { return illnesses.every(function (i) { return i.valid }) }
    function show_hide_button(illness) {
      if ((!illness || illness.valid) && measurements_valid && all_valid()) {
        button.removeClass('disabled')
        button.removeEvents()
        document.removeEvents('keypress')
      } else {
        button.addClass('disabled')
        button.addEvent('click', function(e) {
          alert_fill()
          e.stop()
          return false
        })
        document.addEvent('keypress', function(e) {
          if (event.keyCode == 13) {
            return false;
          } else {
            return true;
          }
        })
      }
    }
    function alert_fill() {
      alert('Veuillez répondre à toutes les questions avant de poursuivre')
    }
    function validate_illness(illness, calculate) {
      illness.valid = illness.fields.every(function(i) {
        if (i.get('type') == 'hidden') {
          return true
        } else if (i.disabled) {
          return true        
        } else if (i.get('type') == 'radio') {
          return i.getParent().getElements('input').some(function(x) { return x.checked })
        } else {
          return i.value.match(/^[0-9]+$/) && parseInt(i.value) >= 0
        }
      })
      if (calculate != false) {
        var str = ''
        illnesses.each(function(i) {
          if (i.get('data-classify-href') > illness.get('data-classify-href')) {
            var h2 = i.getElement('h2')
            h2.getElements('img, ul').dispose()
            h2.removeEvents('click').
            addEvent('click', function() { alert_fill() })
          }
        })
      }
      if (calculate != false && illness.valid) {
        var data = {}
        illnesses.some(function(i) {
          i.getElements('tr').each(function (tr) {
            var sign_id = tr.getElement('input[type=hidden]').get('value')
            tr.getElements('input[type!=hidden], select').some(function (input) {
              if (input.get('type') != 'radio' || input.checked) {
                data['s['+sign_id+']'] = input.value
                return true }})})
          return i == illness })
        var h2 = illness.getElement('h2')
        h2.getElements('img').dispose()
        loader = new Element('img', {src: '/images/loader.gif'}).inject(h2, 'top')
        new Request.JSON({
          url: illness.get('data-classify-href'),
          onSuccess: function(json) {
            var ul = new Element('ul')
            json.each(function (cl) {
              new Element(
                'li', {
                  'class': cl[1].toString(),
                  html:    cl[0] }).inject(ul) })
            var h2 = illness.getElement('h2')
            h2.getElements('img, ul').dispose()
            ul.inject(h2)
          }
        }).get(data)
      }
      if (!illness.valid) illness.getElements('h2 ul').dispose()
      show_hide_button(illness)
      if (illness.getElement('.next button')) {
        if (illness.valid)
          illness.getElement('.next button').removeClass('disabled')
        else
          illness.getElement('.next button').addClass('disabled')
      }
      return illness.valid
    }
    var head_inputs = document.getElements('.profile-child input[type=text]')
    var head_next = document.getElement('.profile-child .next button')
    function validate_measurements() {
      var was_valid = measurements_valid
      measurements_valid = head_inputs.every(function(i) {
        if (i.hasClass('float')) {
          return i.value.match(/^[0-9]+(\.[0-9]+){0,1}$/) && parseFloat(i.value) > 0
        } else if (i.hasClass('integer')) {
          return i.value.match(/^[0-9]+$/) && parseInt(i.value) > 0
        } else {
          return i.value.match(/[^ ]/)
        }
      })
      if (!was_valid && measurements_valid) {
        head_next.removeClass('disabled')
      } else if (was_valid && !measurements_valid) {
        illnesses.each(function(i) { i.addClass('closed') })
        head_next.addClass('disabled')
      }
      if (was_valid != measurements_valid) show_hide_button()
      return measurements_valid
    }
    head_next.addEvent('click', function() {
      if (this.hasClass('disabled'))
        alert_fill()
      else
        open_illness(illnesses[0], false) })
    validate_measurements.periodical(500)

    illnesses.each(function (i,j) {
      i.addClass('closed')
      i.fields = i.getElements('input[type=text], input[type=radio], select')
      if (!first && i.getElement('.fieldWithErrors')) first = i

      if (illnesses[j+1]) {
        i.getElements('.next button').addEvent('click', function(e) {
          if (this.hasClass('disabled'))
            alert_fill()
          else
            open_illness(illnesses[j+1])
        })
      } else {
        i.getElements('.next').dispose()
      }

      i.fields.addEvent('change', function() { validate_illness(i) })
      validate_illness(i, false)
    })

    if (first) { open_illness(first) } else validate_measurements()
  }
})

Element.behaviour(function() {
  this.getElements('form.new_child input[type=text]').addEvent('focus', function() {
    if (this.value == this.get('data-label')) this.value = ''
    this.removeClass('blank')
  }).addEvent('blur', function() {
    if (this.value == '') {
      this.value = this.get('data-label')
      this.addClass('blank')
    } else {
      this.removeClass('blank')
    }
  }).each(function(i) {
    i.fireEvent('blur')
  })

  this.getElements('select.boolean').each(function (sel) {
    var button = new Element('div', { 'class': 'switch' }).injectAfter(sel)
    var yes = new Element('div', { 'class': 'yes', text: 'Oui' }).inject(button)
    var no = new Element('div', { 'class': 'no', text: 'Non' }).inject(button)
    button.sel = sel
    yes.sel = sel
    no.sel = sel
    sel.setStyle('display', 'none')
    set_sc(sel)
  })
  this.getElements('select.boolean+div.switch div').addEvent('click', function(e) {
    this.sel.selectedIndex = (this.hasClass('yes')) ? 2 : 1
    this.sel.fireEvent('change')
    set_sc(this.sel)
    return false
  })

  this.getElements('.photo').addEvent('click', function() {
    var link = document.getElement('link[rel=photo-upload-target]')
    var obj = new Element('object', { width: 300, height: 330 })
    obj.adopt(new Element('param', { name: 'movie', value: '/flash/photo.swf' }))
    obj.adopt(new Element('param', {
      name: 'FlashVars',
      value: 'url=' + (this.get('data-action') || window.location.href) +
             '&field=' + this.get('data-field') +
             (this.get('data-method') ? '&method=' + this.get('data-method') : '')+
             '&domid=' + this.get('id')}))
    transient.open(obj, { width: 300 })
  })

  
  this.getElements('.editable').each(function (div) {
    div.getElements('button.edit').addEvent('click', function() {
      new Request.HTML({
        link: 'ignore', update: div,
        onSuccess: function() { div.updated() }
      }).get(div.get('data-edit-href')) })})

  this.getElements('#child_gender').addEvent('change', function() {
    this.form.getElements('.nee').set(
      'html',
      this.selectedIndex == 0 ? 'Né' : 'Née')
  })
  this.getElements('.confirm').addEvent('click', function() {
    return confirm(this.get('data-confirm') || 'Ok?')
  })
})

function update_image(id, url) {
  if (id && id != '') {
    var div = $(id)
    div.set('html', '')
    new Element('img', { src: url, alt: '' }).inject(div)
  }
  transient.close()
}
function set_sc(sel) {
  switch (sel.selectedIndex) {
    case 1: sel.getNext().removeClass('yes'); sel.getNext().addClass('no'); break;
    case 2: sel.getNext().removeClass('no'); sel.getNext().addClass('yes'); break;
    default: sel.getNext().removeClass('yes'); sel.getNext().removeClass('no')
  }
}

