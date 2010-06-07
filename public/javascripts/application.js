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

transient = {
  div: null,
  open: function(what, style) {
    if (!this.div) {
      this.div = new Element('div', { id: 'transient' }).inject(document.body)
    }
    this.div.setStyles({
      width: (style && style.width ? style.width : '400')+'px',
      visibility: 'hidden' })

    if (typeof(what) == 'object') {
      if (!what.each) what = [what]
      what.each(function(i) { this.div.adopt(i) }.bind(this))
    } else {
      this.div.innerHTML = what
    }

    var size = this.div.getSize()
    this.div.setStyles({
      left: ((window.innerWidth - size.x) / 2) + 'px',
      top: ((window.innerHeight - size.y) / 2) + 'px',
      visibility: 'visible' })
  },
  close: function() { this.div.dispose() },
  ajax: function(url) {
  }
}

window.addEvent('domready', function() { document.body.updated() })

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
    var button = new Element('button', { type: 'button' }).injectAfter(sel)
    button.setAttribute('type', 'button')
    button.sel = sel
    sel.setStyle('display', 'none')
    set_sc(sel)
  })
  this.getElements('select.boolean+button').addEvent('click', function(e) {
    if (this.sel.selectedIndex == 0) {
      this.sel.selectedIndex = (e.page.x < this.getPosition().x + this.getSize().x/2) ? 1 : 2
    } else {
      this.sel.selectedIndex ^= 3
    }
    this.sel.fireEvent('change')
    set_sc(this.sel)
    return false
  })

  this.getElements('.editable').each(function (div) {
    div.getElement('button.edit').addEvent('click', function() {
      new Request.HTML({
        link: 'ignore', update: div,
        onSuccess: function() { div.updated() }
      }).get(div.get('data-edit-url'))
    })
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

  var illnesses = this.getElements('form.new_diagnostic section.illness')
  if (illnesses[0]) {
    var button = document.getElement('form.new_diagnostic button[type=submit]')
    button.setStyle('display', 'none')
    var first = null
    var open_illness = function(illness) {
      illness.getElement('h2').addEvent('click', function() { open_illness(illness) })
      illnesses.each(function(i) { i.addClass('closed') })
      illness.removeClass('closed')
    }

    illnesses.each(function (i,j) {
      if (!first && i.getElement('.fieldWithErrors')) { first = i }
      var answers = i.getElements('input[type=text], input[type=radio], select')
      answers.addEvent('change', function() {
        var fun = function(input) {
          if (input.get('type') == 'radio') {
            return input.getParent().getElements('input').some(function(x) { return x.checked })
          } else {
            return input.value.match(/[a-z0-9]/)
          }
        }
        if (answers.every(fun)) {
          if (illnesses[j+1]) {
            open_illness(illnesses[j+1])
          } else {
            button.setStyle('display', 'block')
          }
        }
      })
    })
    if (!first) first = illnesses[0]
    open_illness(first)
  }
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
    case 1: sel.removeClass('true'); sel.addClass('false'); break;
    case 2: sel.removeClass('false'); sel.addClass('true'); break;
    default: sel.removeClass('true'); sel.removeClass('false')
  }
}

