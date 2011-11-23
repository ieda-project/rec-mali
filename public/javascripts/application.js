(function() {
  var _saved = parseFloat
  parseFloat = function(i) { return _saved(i.replace(',', '.')) }
})()

function $E(a,b) { return document.getElement(a,b) }
Element.implement({
  classes: function() { return this.className.split(/\s+/) },
  updated: function() {
    Element.behaviour_builders.each(function (fun) { fun.apply(this) }.bind(this))
    return this }})
$extend(Element, {
  behaviour_builders: [],
  behaviour: function(fun) {
    this.behaviour_builders.push(fun)
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
		return Math.round(
      document.body.scrollLeft +
      (window.getWidth() - this.getWidth()) / 2);
	},
	ypos: function() {
		return Math.round(
      document.body.scrollTop +
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
  window.alert = function(message) { Alertbox.display(message) }});
    
transient = {
  div: null,
  open: function(what, style) {
    if (!this.div) {
      this.div = new Element('div', { id: 'transient' }).inject(document.body) };
    this.div.innerHTML = '';
    this.div.setStyles({
      width: (style && style.width ? style.width : '400')+'px',
      visibility: 'hidden' });

    if (typeof(what) == 'object') {
      if (!what.each) what = [what];
      what.each(function(i) { this.div.adopt(i) }.bind(this));
    } else this.div.innerHTML = what;
    this.div.updated();

    this.close_button = new Element('div', {'class': 'close-transient', 'text': 'X'});
    this.close_button.addEvent('click', function(e) { this.close() }.bind(this));
    this.close_button.inject(this.div);

    var size = this.div.getSize();
    this.div.setStyles({
      left: ((window.innerWidth - size.x) / 2) + 'px',
      top: ((window.innerHeight - size.y) / 2) + 'px',
      visibility: 'visible' }) },
  close: function() {
    this.div.dispose();
    this.div = false },
  ajax: function(url) {
    new Request.HTML({
      url: url,
      onSuccess: function(tree) { transient.open($A(tree)) }}).get() }};

editing = false;

window.addEvent('domready', function() { document.body.updated() });
window.addEvent('load', function() {
  document.getElements('div.help').each(function (div) {
    var img = null;
    div.getElements('img').each(function(i) {
      if (!img || img.getSize().x < i.getSize().x) img = i; });
    if (img && div.getElement('p').getSize().x < img.getSize().x) {
      div.setStyle('width', img.getSize().x+'px') }})});
window.addEvent('domready', function() {

  document.getElements('a.help').addEvents({
    mouseover: function() {
      var help = $(this.get('href').substr(1));
      help.setStyle('display', 'block');
      var pos = this.getPosition(),
          size = this.getSize(),
          left = [ pos.x, window.getSize().x - help.getSize().x - 20 ].sort()[0];
      help.setStyles({
        left: left+'px',
        top: (pos.y + size.y + 20)+'px' }) },
    mouseout: function() {
      $(this.get('href').substr(1)).setStyles({
        display: 'none',
        top: 0, left: 0 }) },
    click: function() { return false }});

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

  document.getElements('form.diagnostic').each(function (form) {
    var current_illness = null, first = null, illnesses_updated = null,
        button = form.getElement('button[type=submit]').addClass('disabled');

    form.tree = { enfant: {} };
    function run_all_deps(validate) { return };
    function illnesses() { return form.getElements('section.illness') };

    (function(age) {
      if (age) form.tree.enfant = {
        months: age.get('data-months').toInt(),
        age: age.get('data-age').toInt() }})($E('span.age'));
    (function(stem) {
      var y = $(stem+'_1i');
      if (y) {
        var m = $(stem+'_2i'),
            d = $(stem+'_3i'),
            tgt = form.getElement('div.illnesses'),
            today = new Date();
        $$('select[id^='+stem+'_]').addEvent('change', function() {
          tgt.set('html', '');
          if (!y.value || !m.value || !d.value) return run_all_deps(true);
          var bd = new Date(y.value+'-'+m.value+'-'+d.value);
          if (bd.toString() != 'Invalid Date') {
            months = ((today.getFullYear() - y.value.toInt())*12) +
                         (today.getMonth()+1 - m.value.toInt()) -
                         (d.value.toInt() <= today.getDate() ? 0 : 1);
            form.tree.enfant.days = Math.floor((today.getTime() - bd.getTime()) / 86400000);
            form.tree.enfant.months = months;
            form.tree.enfant.age = (months / 12).floor();
            new Request.HTML({
              onSuccess: function(dom) {
                console.log(dom);
                dom[0].getElements('section.illness').each(function (sec) {
                  sec.inject(tgt) });
                illnesses_updated();
                tgt.updated();
                run_all_deps(true);
            }}).get(
              '/children/birthdate?born_on='+
              bd.toISOString().replace(/T.*$/,'')) } else run_all_deps(true) });
        y.fireEvent('change') }})('child_born_on');

    var measurements_valid = true;
    function close_illness() {
      if (current_illness) {
        current_illness.addClass('closed');
        current_illness = null }};
    function open_illness(illness, scroll) {
      close_illness();
      illness.removeClass('closed');
      illness.run_deps();
      current_illness = illness;
      if (!illness.getElement('ul.classification')) validate_illness(illness);
      show_hide_button();
      if (scroll != false) window.scrollTo(0, illness.getPosition().y) };
    function all_valid() { return illnesses().every(function (i) { return i.valid }) };
    function show_hide_button() {
      var is = illnesses();
      if (is[0] && !is.getLast().hasClass('closed') && measurements_valid && all_valid()) {
        button.removeClass('disabled');
        button.removeEvents();
        document.removeEvents('keypress');
      } else {
        button.addClass('disabled');
        button.addEvent('click', function(e) {
          alert_fill();
          e.stop();
          return false });
        document.addEvent('keypress', function(e) {
          if (event.keyCode == 13) {
            return false;
          } else {
            return true }}) }};
    function alert_fill() {
      alert('Veuillez répondre à toutes les questions avant de poursuivre') };
    function invalidate_illness(illness, close) {
      illness.valid = false;
      var h2 = illness.getElement('h2');
      h2.getElements('img, ul').dispose();
      if (close) close_illness() };
    function validate_illness(illness, calculate) {
      if (calculate != false) invalidate_illness(illness);
      illness.valid = illness.fields.every(function(i) {
        if (i.disabled || i.get('type') == 'hidden') {
          return true        
        } else if (i.get('type') == 'radio') {
          return i.getParent().getElements('input').some(function(x) { return x.checked })
        } else {
          return i.value.trim().match(/^[0-9]+$/) && parseInt(i.value) >= 0 }});
      if (calculate != false && illness.valid) {
        var h2 = illness.getElement('h2'),
            data = {}, keys = ['enfant'];
        h2.getElements('img').dispose();
        loader = new Element('img', {src: '/images/loader.gif'}).inject(h2, 'top');

        // Iterate illnesses, but only up to us
        illnesses().some(function(i) {
          keys.push(i.get('data-key'));
          return i == illness });

        keys.each(function(key) {
          for (var subkey in form.tree[key]) data[key+'.'+subkey] = form.tree[key][subkey] });
        new Request.JSON({
          url: illness.get('data-classify-href'),
          onSuccess: function(json) {
            var ul = new Element('ul')
            json.each(function (cl) {
              new Element(
                'li', {
                  'class': (cl[1] || false).toString(),
                  html:    cl[0] }).inject(ul) });
            var h2 = illness.getElement('h2')
            h2.getElements('img, ul').dispose();
            ul.inject(h2) }}).post({
              a: illness.get('data-age-group'),
              d: data })};
      if (!illness.valid) illness.getElements('h2 ul').dispose();
      show_hide_button();
      if (illness.getElement('.next button')) {
        if (illness.valid)
          illness.getElement('.next button').removeClass('disabled')
        else
          illness.getElement('.next button').addClass('disabled') };
      return illness.valid };

    var head_inputs = document.getElements('.profile-child input[type=text]'),
        warnings = $$('.profile-child .warn'),
        head_selects = document.getElements('#child_gender, select[id^=child_born_on]');

    head_inputs.each(function(i) {
      if (i.get('data-validate')) {
        i.validate = new Function(
          'value',
          'try { return('+i.get('data-validate')+') } catch(err) { console.log("Validation error: "+err); return false }') }});
    head_inputs.concat(warnings).each(function(i) {
      if (i.get('data-condition')) {
        i.condition = new Function(
          'data',
          'try { return('+i.get('data-condition')+') } catch(err) { console.log("Condition error: "+err); return false }') }});

    document.getElements('.profile-child input[type=text], .profile-child select').addEvent('change', function(i) {
      illnesses().each(function(i) {
        invalidate_illness(i, true);
        show_hide_button() });
      show_hide_button() });

    var head_next = $E('.profile-child .next button');

    (function () {
      var indices = $E('div.ratios'),
          weight = $E('input[id$=diagnostic_weight]'),
          height = $E('input[id$=diagnostic_height]'),
          gender = $('child_gender'),
          last_indices_data = get_indices_data();
      function get_indices_data() {
        if (weight.valid && height.valid) {
          return new Hash({
            months: form.tree.enfant.months,
            weight: weight.value.toFloat(),
            height: height.value.toFloat(),
            gender: gender ? (gender.selectedIndex == 0) : $E('.profile-child').get('data-gender') })
        } else return null };

      (function() {
        var was_valid = measurements_valid, changes = false;
        measurements_valid = true;
        head_selects.each(function(i) {
          if (i.prev_value != i.value) {
            changes = true
            i.prev_value = i.value }})
        head_inputs.each(function(i) {
          if (i.condition) {
            if (i.condition(form.tree)) {
              if (i.disabled) {
                changed = true
                i.disabled = false
                i.prev_value = null
                i.removeClass('disabled').disabled = false }
            } else {
              if (!i.disabled) {
                changed = true
                i.addClass('disabled').disabled = true
                i.valid = true
                i.value = '' }}}
          if (i.prev_value != i.value) {
            changes = true;
            i.prev_value = i.value;
            var value = null;
            if (!i.disabled) {
              if (!i) {
                i.valid = i.hasClass('needed');
              } else if (i.hasClass('float')) {
                value = i.value.toFloat();
                i.valid = !isNaN(value) &&
                  i.value.trim().match(/^[0-9]*([.,][0-9]+){0,1}$/) &&
                  (!i.validate || i.validate(value));
              } else if (i.hasClass('integer')) {
                value = i.value.toInt();
                i.valid = !isNaN(value) &&
                  i.value.trim().match(/^[0-9]+$/) &&
                  (!i.validate || i.validate(value));
              } else {
                value = i.value;
                i.valid = value.match(/[^ ]/) }}
            var key = i.get('data-key')
            if (!value || i.valid) { i.removeClass('invalid') } else i.addClass('invalid');
            if (key) form.tree.enfant[key] = value }
          if (!i.disabled && !i.valid) measurements_valid = false });

        if (!changes) return;
        head_next.setStyle('visibility', 'visible');
        close_illness();

        if (!was_valid && measurements_valid) {
          head_next.setStyle('visibility', 'visible');
          head_next.removeClass('disabled');
        } else if (was_valid && !measurements_valid) {
          close_illness();
          head_next.setStyle('visibility', 'visible');
          head_next.addClass('disabled'); }
        if (was_valid != measurements_valid) show_hide_button();
        if (measurements_valid) {
          warnings.setStyle('display', 'none')
        } else {
          warnings.each(function (w) {
            w.setStyle('display', w.condition(form.tree) ? 'none' : 'block') })};

        var data = get_indices_data();
        if (data && data.height && data.weight) {
          if (last_indices_data && data.every(function(value, key) { return last_indices_data[key] == value })) return
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
                    li.addClass('warning') } else li.removeClass('warning') };
                li.getElement('.value').set('text', v[0]).setStyle(
                  'font-size', v[0] > 999 ? '0.9em' : '1em') }
              form.tree.enfant.wfa = json.weight_age[0];
              form.tree.enfant.hfa = json.height_age[0];
              form.tree.enfant.wfh = json.weight_height[0];
              last_indices_data = data }}).get({ d: data.getClean() });
        } else {
          // No data
          last_indices_data = null;
          [ 'weight_age', 'height_age', 'weight_height' ].each(function (index) {
            var li = indices.getElement('.'+index)
            li.removeClass('alert').removeClass('warning').addClass('disabled')
            li.getElement('.value').set('text', '-') })}}).periodical(150) })();

    head_next.addEvent('click', function() {
      if (this.hasClass('disabled'))
        alert_fill()
      else {
        open_illness(illnesses()[0], false)
        this.setStyle('visibility', 'hidden') }});

    illnesses_updated = function() {
      var is = illnesses();
      is.each(function (i,j) {
        i.addClass('closed').getElement('h2').addEvent('click', function() {
          if (current_illness == i) return
          var yes = current_illness && current_illness.getAllPrevious('section.illness').some(function(ii) {
            return ii == i })
          yes ? open_illness(i) : alert_fill() })
        i.fields = i.getElements('input[type=text], input[type=radio], select')
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

        i.run_deps = function(validate) {
          var change = false;
          i.fields.each(function (s) {
            if (s.dep) {
              var old = s.disabled;
              s.disabled = !s.dep(form.tree);
              if (old != s.disabled) change = true;
              var td = s.getParent();
              if (s.disabled) {
                if (!td.ghost) {
                  td.ghost = new Element('input', { type: 'hidden', name: s.name, value: '' }).inject(td)
                  td.getElements('*').each(function (el) {
                    el.old_display = el.getStyle('display')
                    el.setStyle('display', 'none') })
                  td.na = new Element('div', { text: 'Non applicable' }).inject(td) }
              } else if (td.ghost) {
                td.ghost.dispose()
                td.na.dispose()
                delete td.ghost
                delete td.na
                td.getElements('*').each(function (el) { el.setStyle('display', el.old_display) }) }}
          });
          if (validate && change) validate_illness(i) }

        i.fields.addEvent('change', function() {
          copy_value(this);
          i.run_deps() });
        i.run_deps();

        if (!first && i.getElement('.fieldWithErrors')) first = i

        if (is[j+1]) {
          i.getElements('.next button').addEvent('click', function(e) {
            if (this.hasClass('disabled'))
              alert_fill()
            else
              open_illness(is[j+1]) })
        } else { i.getElements('.next').dispose() };

        i.fields.addEvent('change', function() {
          i.getAllNext('section.illness').each(function(j) { invalidate_illness(j) })
          validate_illness(i) });
        validate_illness(i, false) })};
  illnesses_updated() })});

Element.behaviour(function() {
  function pending() {
    if ($E('html').hasClass('pending')) return false;
    $E('html').addClass('pending');
    new Element('div', {
      'class': 'page-loader',
      'styles': { top: (document.body.scrollTop + 100) + 'px' }}).inject(document.body);
    return true };
  this.getElements('nav a, ul.menu a, ul#breadcrumbs a, a.wait').addEvent('click', function() {
    if (pending()) {
      this.addClass('clicked');
      return true } else return false });
  this.getElements('form').addEvent('submit', function() {
    if (pending()) {
      $$('button[type=submit]').each(function(i) {
        i.addClass('clicked')
        i.disabled = true });
      return true } else return false });

  this.getElements('form.new_child input[type=text]').addEvent('focus', function() {
    if (this.value == this.get('data-label')) this.value = '';
    this.removeClass('blank')
  }).addEvent('blur', function() {
    if (this.value == '') {
      this.value = this.get('data-label');
      this.addClass('blank')
    } else this.removeClass('blank')
  }).each(function(i) {
    i.fireEvent('blur') });

  this.getElements('select.boolean').each(function (sel) {
    var button = new Element('div', { 'class': 'switch' }).injectAfter(sel);
    var yes = new Element('div', { 'class': 'yes', text: 'Oui' }).inject(button);
    var no = new Element('div', { 'class': 'no', text: 'Non' }).inject(button);
    button.sel = sel;
    yes.sel = sel;
    no.sel = sel;
    sel.setStyle('display', 'none');
    set_sc(sel) });
  this.getElements('select.boolean+div.switch div').addEvent('click', function(e) {
    this.sel.selectedIndex = (this.hasClass('yes')) ? 2 : 1;
    this.sel.fireEvent('change');
    set_sc(this.sel);
    return false });

  this.getElements('.photo').addEvent('click', function() {
    if (editing || window.location.href.match(/\/(new|edit)\/*$/)) {
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
    } else {
      var thmb = this.getElement('img')
      if (thmb.src.match('missing')) return false
      transient.open(
        new Element('img', {
          src: thmb.src.replace('thumbnail', 'normal'),
          width: 300, height: 300 }),
        { width: 300 })
    }
  })
  
  this.getElements('.ratios li').addEvent('click', function(e) {
    if (this.hasClass('disabled'))
      return;
    var graph = this.getElement('div.graph').clone()
    transient.open(graph, { width: 420 })});

  
  this.getElements('.editable').each(function (div) {
    div.getElements('button.edit').addEvent('click', function() {
      new Request.HTML({
        link: 'ignore', update: div,
        onSuccess: function() {
          div.updated();
          editing = true }}).get(div.get('data-edit-href')) })});

  this.getElements('#child_gender').addEvent('change', function() {
    this.form.getElements('.nee').set(
      'html',
      this.selectedIndex == 0 ? 'Né' : 'Née') });
  this.getElements('.confirm').addEvent('click', function() {
    return confirm(this.get('data-confirm') || 'Ok?') });
  this.getElements('a.transient').addEvent('click', function() {
    transient.ajax(this.get('href'));
    return false });

  this.getElements('div.aided-search').each(function(div) {
    var input  = div.getElement('input'),
        ul     = div.getElement('ul'),
        values = [], prev=null, checker=null;

    input.focus();
    div.getElements('option').each(function (option) {
      var v = option.get('text');
      values.push({
        text: v,
        lc: v.toLowerCase(),
        id: option.get('value') }) });

    ul.addEvent('click', function(e) {
      var id = e.target.get('data-id');
      if (id) {
        $(div.get('data-target')).adopt(
          new Element('option', {
            value: id,
            selected: 'selected',
            text: div.get('data-prefix') + e.target.get('text') }));
        $clear(checker);
        transient.close() }});

    checker = (function () {
      if (!input.value) return(ul.set('html', ''));
      if (prev != input.value) {
        ul.set('html', '');
        for (var i = 0, c = 0; c < 10 && values[i]; i++) {
          var v = values[i];
          if (v.lc.indexOf(input.value.toLowerCase()) > -1) {
            new Element('li', { text: v.text, 'data-id': v.id }).inject(ul);
            c++ }}
        prev = input.value }}).periodical(500) })});

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

