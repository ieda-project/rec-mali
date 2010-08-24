function $E(a,b) { return document.getElement(a,b) }
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
  if (link = $E('link.auto-post')) {
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
        if (next = $E('link[rel=next]')) window.location = next.href }}).post() }

  /* ILLNESSES */

  illnesses = document.getElements('form.diagnostic section.illness')
  if (illnesses[0]) {
    var form = $E('form.diagnostic')
    form.tree = { enfant: {} };
    (function(age) {
      if (age) form.tree.enfant = {
        months: age.get('data-months').toInt(),
        age: age.get('data-age').toInt() }
    })($E('span.age'))
    var button = form.getElement('button[type=submit]').addClass('disabled')
    var first = null;

    (function(stem) {
      var today = new Date()
      var y
      if (y = $(stem+'_1i')) {
        var m = $(stem+'_2i')
        var d = $(stem+'_3i')
        $$('select[id^='+stem+'_]').addEvent('change', function() {
          months = ((today.getFullYear() - y.value.toInt())*12) +
                       (today.getMonth()+1 - m.value.toInt()) -
                       (d.value.toInt() <= today.getDate() ? 0 : 1)
          if (months < 0) months = 0
          form.tree.enfant.months = months
          form.tree.enfant.age = (months / 12).floor()
        })
        y.fireEvent('change')
      }
    })('child_born_on')

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
        if (i.disabled || i.get('type') == 'hidden') {
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
        var h2 = illness.getElement('h2')
        h2.getElements('img').dispose()
        loader = new Element('img', {src: '/images/loader.gif'}).inject(h2, 'top')
        var data = {}
        var keys = ['enfant']
        illnesses.some(function(i) { keys.push(i.get('data-key')); return i == illness })
        keys.each(function(key) {
          for (var subkey in form.tree[key]) data[key+'.'+subkey] = form.tree[key][subkey]
        })
        new Request.JSON({
          url: illness.get('data-classify-href'),
          onSuccess: function(json) {
            var ul = new Element('ul')
            json.each(function (cl) {
              new Element(
                'li', {
                  'class': (cl[1] || false).toString(),
                  html:    cl[0] }).inject(ul) })
            var h2 = illness.getElement('h2')
            h2.getElements('img, ul').dispose()
            ul.inject(h2)
          }
        }).get({ d: data })
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
    var head_next = $E('.profile-child .next button')

    var last_indices_data = null
    function refresh_indices() {
      if (!measurements_valid) {
        if (last_indices_data) {
          [ 'weight_age', 'height_age', 'weight_height' ].each(function (index) {
            var li = $E('.ratios .'+index)
            li.removeClass('alert').removeClass('warning').addClass('disabled')
            li.getElement('.value').set('text', '-') })
        }
        return
      }
      var indices = $E('div.ratios')
      var g = $('child_gender')
      var data = new Hash({
        months: form.tree.enfant.months,
        weight: $E('input[id$=diagnostic_weight]').value.toInt(),
        height: $E('input[id$=diagnostic_height]').value.toInt(),
        gender: g ? (g.selectedIndex == 0) : $E('.profile-child').get('data-gender') })
      if (last_indices_data && data.every(function(value, key) { return last_indices_data[key] == value })) return
      last_indices_data = data
      new Request.JSON({
        url: '/children/calculations',
        onSuccess: function(json) {
          for (index in json) {
            var v = json[index]
            var li = $E('.ratios .'+index)
            li.removeClass('disabled')
            if (v[0] < v[2]) {
              li.addClass('alert')
            } else {
              li.removeClass('alert')
              if (v[0] < v[1]) {
                li.addClass('warning')
              } else li.removeClass('warning')
            }
            li.getElement('.value').set('text', v[0]).setStyle(
              'font-size', v[0] > 999 ? '0.9em' : '1em')
          }
          form.tree.enfant.wfa = json.weight_age[0]
          form.tree.enfant.hfa = json.height_age[0]
          form.tree.enfant.wfh = json.weight_height[0]
        }
      }).get({ d: data.getClean() })
    }
    function validate_measurements() {
      var was_valid = measurements_valid
      measurements_valid = head_inputs.every(function(i) {
        if (i.hasClass('optional')) {
          return true
        } else if (i.hasClass('float')) {
          return i.value.match(/^[0-9]+([\.,][0-9]+){0,2}$/) && parseFloat(i.value) > 0
        } else if (i.hasClass('integer')) {
          return i.value.match(/^[0-9]+$/) && parseInt(i.value) > 0
        } else {
          return i.value.match(/[^ ]/)
        }
      })
      if (!was_valid && measurements_valid) {
        head_next.setStyle('visibility', 'visible')
        head_next.removeClass('disabled')
      } else if (was_valid && !measurements_valid) {
        illnesses.each(function(i) { i.addClass('closed') })
        head_next.setStyle('visibility', 'visible')
        head_next.addClass('disabled')
      }
      if (was_valid != measurements_valid) show_hide_button()
      return measurements_valid
    }
    head_next.addEvent('click', function() {
      if (this.hasClass('disabled'))
        alert_fill()
      else {
        open_illness(illnesses[0], false)
        head_next.setStyle('visibility', 'hidden')
      }})
    validate_measurements.periodical(100)
    refresh_indices.periodical(250)

    illnesses.each(function (i,j) {
      i.addClass('closed')
      i.fields = i.getElements('input[type=text], input[type=radio], select')
      i.getElement('h2').addEvent('click', function() { alert_fill() })
      var obj = form.tree[i.get('data-key')] = {}
      function copy_value(sign) {
        var value
        switch (sign.type) {
          case 'text':
            value = parseInt(sign.value)
            if (isNaN(value)) value = 0
            break
          case 'select-one':
            value = [null, false, true][sign.selectedIndex]
            break
          case 'radio':
            if (!sign.checked) return
            value = sign.value
        }
        obj[sign.get('data-key')] = value
      }
      i.fields.each(function(s) {
        copy_value(s)
        if(s.get('data-dep')) {
          s.dep = new Function('data', 'try { return('+s.get('data-dep')+') } catch(err) { console.log("Dependency error: "+err); return false }')
        }
      })

      function run_deps() {
        i.fields.each(function (s) {
          if (s.dep) {
            s.disabled = !s.dep(form.tree)
            var td = s.getParent()
            if (s.disabled) {
              if (!td.ghost) {
                td.ghost = new Element('input', { type: 'hidden', name: s.name, value: '' }).inject(td)
                td.getElements('*').each(function (el) {
                  el.old_display = el.getStyle('display')
                  el.setStyle('display', 'none') })
                td.na = new Element('div', { text: 'Non applicable' }).inject(td)
              }
            } else if (td.ghost) {
              td.ghost.dispose()
              td.na.dispose()
              delete td.ghost
              delete td.na
              td.getElements('*').each(function (el) { el.setStyle('display', el.old_display) })
            }
          }
        })
      }

      i.fields.addEvent('change', function() {
        copy_value(this)
        run_deps()
      })
      run_deps()

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
    var link = $E('link[rel=photo-upload-target]')
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
  
  this.getElements('.ratios li').addEvent('click', function(e) {
    if (this.hasClass('disabled'))
      return;
    var graph = this.getElement('div.graph').clone()
    transient.open(graph, { width: 420 })
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

