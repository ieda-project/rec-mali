(function() {
  var _saved = parseFloat
  parseFloat = function(i) { return _saved(i.replace(',', '.')) }
})()

Date.prototype.fullMonthsFrom = function(a) {
  var diff;
  diff = this.getMonth() - a.getMonth();
  diff += (this.getYear() - a.getYear()) * 12;
  if (this.getDate() < a.getDate()) diff -= 1;
  return diff }

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

// Globals for AS-JS communication

var today, photo_saved, photo_params, auto_answer = {},
    sel_classes = { dunno: 0, yes: 2, no: 1 };

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
  open: function(what, style, closer) {
    if (!this.div) {
      this.div = new Element('div', { id: 'transient' }).inject(document.body);
      this.div.addEvent('mousewheel', function(e) { e.stopPropagation() });
      this.content = new Element('div', { class: 'content' }).inject(this.div)
      this.closer = closer;
      this.close_button = new Element('div', {'class': 'close-transient', 'text': 'X'});
      this.close_button.addEvent('click', function(e) { this.close() }.bind(this));
      this.close_button.inject(this.div) };
    if (style && style.class) {
      this.div.set('class', style.class);
      delete style.class };

    this.div.setStyles({
      display: 'block',
      height: 'auto',
      width: ((style && style.width) ?
        (style.width + this.content.getStyle('padding-left').toInt() + this.content.getStyle('padding-right').toInt()) + 'px' :
        'auto'),
      visibility: 'hidden' });
    this.content.setStyle('height', ((style && style.height) ? style.height : 'auto'));

    if (typeof(what) == 'object') {
      if (!what.each) what = [what];
      what.each(function(i) { this.content.adopt(i) }.bind(this));
    } else this.content.innerHTML = what;
    this.content.updated();
    var sh = this.content.getScrollSize().y + this.content.getStyle('padding-bottom').toInt();
    if (sh > 400) sh = 400;
    this.div.setStyle('height', sh+'px');
    this.content.setStyle(
      'height',
      (sh -
       this.content.getStyle('padding-bottom').toInt() -
       this.content.getStyle('padding-top').toInt()) + 'px');

    var size = this.div.getSize();
    this.div.setStyles({
      left: ((window.innerWidth - size.x) / 2) + 'px',
      top: ((window.innerHeight - size.y) / 2) + 'px',
      visibility: 'visible' }) },
  close: function() {
    if (this.closer) this.closer();
    this.content.innerHTML = '';
    this.div.setStyle('display', 'none') },
  ajax: function(url) {
    new Request.HTML({
      url: url,
      onSuccess: function(tree) { transient.open($A(tree)) }}).get() }};

window.addEvent('domready', function() {
  document.getElements('a.help').addEvent('click', function() {
    transient.open($(this.get('href').substr(1)).get('html'), { width: '650px', class: 'treatment-help' }) });

  document.getElements('section.treatment input[type=radio]').addEvents({
    mousedown: function() {
      if (this.checked) this.clear = true;
    },
    click: function() {
      if (this.clear) {
        this.clear = false;
        this.checked = false }}});

  document.getElements('section.treatment label').addEvents({
    mousedown: function() {
      var radio = $(this.get('for'))
      if (radio.checked) radio.clear = true;
    },
    mouseover: function() {
      if (this.checked) {
        this.title = null
      } else {
        var other=null;
        $$('input[name="'+$(this.get('for')).name+'"]').some(function (i) {
          if (i.checked) {
            other = i;
            return true }});
        if (other) {
          this.title =
            'Médicament sélectionné pour la classification "'+
            other.getParent('section').getElement('h2').get('text') + '"'
        } else this.title = 'Médicament non sélectionné' }},
    mouseout: function() {
      this.title = null;
    }});

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
    function illnesses() { return form.getElements('section.illness') };
    illnesses().each(function (i) { i.protect = !!(i.getElement('li.true') || i.getElement('li.false')) });

    (function(age) {
      if (age) {
        var temp = age.get('data-diag-date');
        if (temp) today = new Date(temp);
        form.tree.enfant = {
          days: age.get('data-days').toInt(),
          months: age.get('data-months').toInt(),
          age: age.get('data-age').toInt() }}})($E('span.age'));

    if (!today) today = new Date();
    ['child_born_on', 'diagnostic_born_on'].each(function(stem) {
      var y = $(stem+'_1i');
      if (y) {
        var vacc = $E('.vaccinations'),
            m = $(stem+'_2i'),
            d = $(stem+'_3i'),
            tgt = form.getElement('div.illnesses');
        $$('select[id^='+stem+'_]').addEvent('change', function() {
          tgt.set('html', '');
          if (!y.value || !m.value || !d.value) {
            vacc.set('html', '');
            return
          }

          var bd = new Date(y.value+'-'+m.value+'-'+d.value), months,
              iso = bd.toISOString().replace(/T.*$/, '');

          if (bd.getDate() == d.value && bd < today &&
             (months = ((today.getFullYear() - y.value.toInt())*12) +
                        (today.getMonth()+1 - m.value.toInt()) -
                        (d.value.toInt() <= today.getDate() ? 0 : 1)) < 60) {
            form.tree.enfant.days = Math.floor((today.getTime() - bd.getTime()) / 86400000);
            form.tree.enfant.months = months;
            form.tree.enfant.age = (months / 12).floor();
            new Request.HTML({
              onSuccess: function(dom) {
                vacc.set('html', '')
                dom[0].getElements('.vaccinations>*').each(function (el) {
                  el.inject(vacc) });
                dom[0].getElements('section.illness').each(function (sec) {
                  sec.inject(tgt) });
                vacc.updated();
                illnesses_updated();
                tgt.updated();
            }}).get(
              form.get('data-questionnaire') +
              '?born_on='+
              iso);
          } else {
            vacc.set('html', '');
            delete form.tree.enfant.days;
            delete form.tree.enfant.months;
            delete form.tree.enfant.age }});
        y.fireEvent('change') }});

    var measurements_valid = true;
    var scores_valid = true;
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
      if (illness.protect) {
        illness.valid = true;
        (function () { illness.protect = false }).delay(10);
        return };
      if (calculate != false) invalidate_illness(illness);
      illness.valid = illness.fields.every(function(i) {
        if (i.disabled || i.get('type') == 'hidden') {
          return true
        } else if (i.type == 'select-one') {
          return i.selectedIndex > 0;
        } else if (i.get('type') == 'radio') {
          return i.getParent().getElements('input').some(function(x) { return x.checked })
        } else {
          var intv, mm;
          if (!i.value.trim().match(/^[0-9]+$/) || (intv = parseInt(i.value)) < 0) return false;
          mm = parseInt(i.get('data-min'));
          if (mm && intv < mm) return false;
          mm = parseInt(i.get('data-max'));
          if (mm && intv > mm) return false;
          return true;
        }});
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
        head_selects = document.getElements('#child_gender, select[id^=child_born_on], #child_village_id, #diagnostic_distance');

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
          temp = $E('input[id$=diagnostic_temperature]'),
          gender = $('child_gender'),
          last_indices_data = get_indices_data();
      function get_indices_data() {
        if (weight.valid && height.valid) {
          return new Hash({
            months: form.tree.enfant.months,
            days: form.tree.enfant.days,
            weight: form.tree.enfant.weight,
            height: form.tree.enfant.height,
            gender: gender ? (gender.selectedIndex == 0) : $E('.profile-child').get('data-gender') })
        } else return null };

      var f = function() {
        var was_valid = measurements_valid, changes = false;
        measurements_valid = true;
        var abnormal_ranges = $$('.abnormal_ranges')[0];
        var was_score_valid = scores_valid
        scores_valid = abnormal_ranges.getElement('.switch').hasClass('yes');
        if (was_score_valid != scores_valid) changes = true;
        if (!(form.tree.enfant.months >= 0) || form.tree.months >= 60) measurements_valid = false;
        head_selects.each(function(i) {
          var opt = i.selectedOptions[0]
          if (!i.value && (!opt || !opt.get('data-village'))) measurements_valid = false; // HACK HACK
          if (i.prev_opt != opt) {
            changes = true
            i.prev_opt = opt }});

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

        if (measurements_valid) {
          warnings.setStyle('display', 'none')
        } else {
          warnings.each(function (w) {
            w.setStyle('display', w.condition(form.tree) ? 'none' : 'block') })};

        head_next.setStyle('visibility', 'visible');
        close_illness();

        if ((!was_valid || !was_score_valid) && measurements_valid && scores_valid) {
          head_next.setStyle('visibility', 'visible');
          head_next.removeClass('disabled');
        } else if ((was_valid || was_score_valid) && (!measurements_valid || !scores_valid)) {
          close_illness();
          head_next.setStyle('visibility', 'visible');
          head_next.addClass('disabled'); }

        if (was_valid != measurements_valid) show_hide_button();

        form.tree.enfant.weight = weight.value.toFloat();
        form.tree.enfant.height = height.value.toFloat();
        form.tree.enfant.temp = temp.value.toFloat();
        var abnormal_score = false;
        var data = get_indices_data();
        if (data && data.height && data.weight) {
          if (!last_indices_data || !data.every(function(value, key) { return last_indices_data[key] == value })) {
            new Request.JSON({
              url: '/children/calculations',
              onSuccess: function(json) {
                for (index in json) {
                  var v = json[index]
                  var li = $E('.ratios .'+index)
                  li.removeClass('disabled')
                  if (v[0] < v[3]) {
                    li.addClass('alert')
                  } else {
                    li.removeClass('alert')
                    if (v[0] < v[2]) {
                      li.addClass('warning') }
                    else li.removeClass('warning')
                  };
                  if (Math.abs(v[1]) >= 3) abnormal_score = true;
                  li.getElement('.value').set('text', v[0]).setStyle(
                    'font-size', v[0] > 999 ? '0.9em' : '1em');
                  var score = v[1].toString();
                  if (score.indexOf('.') == -1) score += '.0';
                  li.getElement('.score').set('text', score).setStyle(
                    'font-size', score.length > 3 ? '0.9em' : '1em') }
                abnormal_ranges.getElement('.switch').removeClass('yes').removeClass('no').addClass(abnormal_score ? 'no' : 'yes')
                abnormal_ranges.setStyle('display', abnormal_score ? 'block' : 'none')

                form.tree.enfant.wfa = json.weight_age[0];
                form.tree.enfant.hfa = json.height_age[0];
                form.tree.enfant.wfh = json.weight_height[0];
                last_indices_data = data }}).get({ d: data.getClean() }) };
        } else {
          // No data
          last_indices_data = null;
          [ 'weight_age', 'height_age', 'weight_height' ].each(function (index) {
            var li = indices.getElement('.'+index)
            li.removeClass('alert').removeClass('warning').addClass('disabled')
            li.getElement('.value').set('text', '-')
            li.getElement('.score').set('text', '-') }) };

        var aa_illnesses = {};
        for (code in auto_answer) {
          var res = auto_answer[code](form.tree), td = $(code), s = code.split('.');
          if (!td) continue;
          if (!form.tree[s[0]]) form.tree[s[0]] = {};
          if (td.auto) {
            try { if (res == form.tree[s[0]][s[1]]) continue } catch(e) {}
          } else td.auto = true;
          aa_illnesses[s[0]] = true;
          if (res != null) {
            form.tree[s[0]][s[1]] = res;
            if (typeof(res) == 'boolean') {
              var dis = td.getElement('.switch').removeClass('disabled')
              td.getElement(res ? '.yes' : '.no').fireEvent('click');
              dis.addClass('disabled');
            } else {
              var dis = td.getElements('input[type=radio]').set('disabled', false);
              dis.filter(function (i) { return i.value == res }).set('checked', true);
              dis.set('disabled', true);
              var hidden = td.getElement('input[type=hidden]') || new Element('input', { type: 'hidden', name: dis[0].name }).inject(td);
              hidden.value = res;
            }
          } else {
            form.tree[s[0]][s[1]] = null;
            td.getElements('.switch').removeClass('disabled').each(function (i) {
              i.sel.selectedIndex = 0;
              i.removeClass('yes').removeClass('no');
              i.sel.fireEvent('changed') });
            td.getElements('input[type=radio]').set('disabled', false).set('checked', false);
            td.getElements('input[type=hidden]').dispose(); }}
        illnesses().each(function(i) {
          if (aa_illnesses[i.get('data-key')]) validate_illness(i, true) })};
      f(); f.periodical(150) })();

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
        i.fields = i.getElements('input[type=text], input[type=radio], select');
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
          i.getElements('td.answer').each(function (td) {
            var flds = td.getElements('input[type=radio], input[type=text], select'), s = flds[0];
            if (s.dep) {
              var old = s.disabled;
              flds.set('disabled', !s.dep(form.tree));
              if (old != s.disabled) {
                change = true;
                if (s.disabled) {
                  td.getChildren().each(function (el) {
                    el.old_display = el.getStyle('display');
                    el.setStyle('display', 'none') });
                  new Element('input', { class: 'nonapp', type: 'hidden', name: s.name, value: '' }).inject(td);
                  new Element('div', { class: 'nonapp', text: 'Non applicable' }).inject(td);
                } else {
                  td.getElements('.nonapp').dispose();
                  td.getChildren().each(function (el) { el.setStyle('display', el.old_display) })}}}});
          if (validate && change) validate_illness(i) };

        i.fields.addEvent('change', function() {
          copy_value(this);
          i.run_deps() });
        i.run_deps.delay(10, i);

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
  illnesses_updated();
  })});

window.addEvent('domready', function() { document.body.updated() });

Element.behaviour(function() {
  this.getElements('#child_village_id').addEvent('change', function() {
    var name;
    if (this.value || this.selectedIndex == 0) {
      name = null;
    } else {
      var opt = this.getElements('option')[this.selectedIndex];
      name = opt.get('data-village');
      if (!name) {
        name = prompt("Nom du village:");
        if (name) {
          $A(this.options).each(function(i) {
            if (i.get('data-village')) i.dispose() });
          document.createElement('option').
            set('data-village', name).
            set('value', null).
            set('text', 'Hors zone: '+name).
            injectBefore(this.getElement('option:last-child'));
          this.selectedIndex = this.options.length - 2;
        } else {
          this.selectedIndex = 0;
          alert('Entrée invalide, valeur remis à '+opt.get('text'));
          name = null }}}
    $('child_village_name').value = name;
  });

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
    if (sel.hasClass('negative')) button.addClass('negative');
    var yes = new Element('div', { 'class': 'yes', text: 'Oui' }).inject(button);
    if (sel.hasClass('nullable')) {
      var dunno = new Element('div', { 'class': 'dunno', text: '?' }).inject(button);
      dunno.sel = sel;
    }
    var no = new Element('div', { 'class': 'no', text: 'Non' }).inject(button);
    button.sel = sel;
    yes.sel = sel;
    no.sel = sel;
    sel.setStyle('display', 'none');
    set_sc(sel) });
  this.getElements('select.boolean+div.switch div').addEvent('click', function(e) {
    if (this.getParent().hasClass('disabled')) return;
    this.sel.selectedIndex = sel_classes[this.className];
    this.sel.fireEvent('change');
    set_sc(this.sel);
    return false });
  this.getElements('.abnormal_ranges div.switch div').addEvent('click', function(e) {
    this.getParent().removeClass('yes').removeClass('no').addClass(this.get('class'))
    return false });

  this.getElements('.photo button').addEvent('click', function(e) {
    e.stopPropagation();
    var self = this.getParent();
    new Request.JSON({
      method: self.get('data-method'),
        onSuccess: function(json) {
          self.getElement('img').src = json.photo;
          if (!json.present) self.removeClass('present').addClass('absent');
        },
        data: self.get('data-field')+'=',
        url: self.get('data-action') }).send();
  });

  this.getElements('.photo').addEvent('click', function() {
    if (this.hasClass('editing')) {
      var obj, closer=null, self=this;
      if (navigator.webkitGetUserMedia) {
        // HTML5 Camera
        obj = new Element('div', {class: 'html-camera'});
        var lms,
            vid = new Element('video', {autoplay: true}).inject(obj),
            cnv = new Element('canvas').inject(obj),
            take = new Element('button', {text: 'Prendre', class: 'take'}).inject(obj),
            retake = new Element('button', {text: 'Reprendre', class: 'retake'}).inject(obj),
            save = new Element('button', {text: 'Sauver', class: 'save'}).inject(obj),
            ctx = cnv.getContext('2d');

        navigator.webkitGetUserMedia({video: true}, function(stream) {
          vid.src = window.URL.createObjectURL(stream);
          lms = stream;
        }, console.log);

        closer = function() {
          if (lms) {
            lms.stop();
            lms = null }}

        take.addEvent('click', function() {
          if (lms) {
            cnv.width = vid.videoWidth; cnv.height = vid.videoHeight;
            ctx.drawImage(vid, 0, 0);
            vid.pause();
            take.setStyle('display', 'none');
            retake.setStyle('display', 'block');
            save.setStyle('display', 'block') }});

        retake.addEvent('click', function() {
          vid.play();
          take.setStyle('display', 'block');
          retake.setStyle('display', 'none');
          save.setStyle('display', 'none') });

        save.addEvent('click', function() {
          var data = cnv.toDataURL('image/png');
          img = new Image(cnv.width, cnv.height);
          img.src = data;
          new Request.JSON({
            method: self.get('data-method') || 'put',
            onSuccess: function(json) {
              self.getElement('img').src = json.photo;
              self.removeClass('absent').addClass('present');
              transient.close();
            },
            data: self.get('data-field')+'='+data.substr(data.indexOf(',')+1),
            url: self.get('data-action') }).send(); });
      } else {
        // Flash camera
        obj = new Element('object', { width: 340, height: 380 });
        obj.adopt(new Element('param', { name: 'movie', value: '/flash/photo.swf' }));

        photo_params = function() {
          return {
            action: self.get('data-action'),
            paramName: self.get('data-field'),
            method: self.get('data-method') || 'put' }};
        photo_saved = function(uri) {
          self.getElement('img').src = uri;
          transient.close() };
      }
      transient.open(obj, { width: 340, height: 380 }, closer);
    }});

  this.getElements('.ratios li').addEvent('click', function(e) {
    if (this.hasClass('disabled'))
      return;
    var graph = this.getElement('div.graph').clone()
    transient.open(graph, { width: 420 })});

  var editables = this.getElements('.editable');
  if (editables[0] && !today) {
    today = new Date();
    editables.each(function (div) {
      div.getElements('button.edit').addEvent('click', function() {
        new Request.HTML({
          link: 'ignore', update: div,
          onSuccess: function() {
            div.getElement('form').addEvent('submit', function(e) {
              if (div.getElements('.required').some(function (i) {
                var opt=null;
                if (i.selectedOptions) opt=i.selectedOptions[0];
                if (!i.value && (!opt || !opt.get('data-village'))) {
                  alert("Un champ obligatoire est manquant.");
                  i.focus();
                  return true;
                } else return false })) {
                  this.stop = true;
                  return false };
              var flds = this.getElements('select[id^=child_born_on_]'),
                  bd = new Date(flds[2].value + '-' + flds[1].value + '-' + flds[0].value);
              if (!flds[0].value || bd.getDate() != flds[0].value || bd > today || today.fullMonthsFrom(bd) > 59) {
                alert("L'âge de l'enfant doit être compris entre 0 et 59 mois.");
                this.stop = true;
                return false };
              this.stop = false });
            div.updated();
            $$('.photo').addClass('editing'); }}).get(div.get('data-edit-href')) })})};

  var nee = [ "Né/e", "Né", "Née" ];

  this.getElements('#child_gender').addEvent('change', function() {
    this.form.getElements('.nee').set('html', nee[this.selectedIndex]) });
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
        prev = input.value }}).periodical(500) });

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
    if (this.stop) return;
    if (this.validate && !this.validate()) return false;
    if (pending()) {
      $$('button[type=submit]').each(function(i) {
        i.addClass('clicked')
        i.disabled = true });
      return true } else return false })

  var admin_switch = this.getElement('select#user_admin')
  if (admin_switch) {
    var form = admin_switch.getParent('form')
    form.validate = function() {
      if ($('user_admin').value == '1')
        return confirm(form.get('data-admin-confirm'));
      return true
    }
  }

  this.getElements('select.autolink').each(function(select) {
    url = select.get('data-url')
    this.addEvent('change', function(e) {
      window.location.href = select.value
    })
  })
});

function update_image(id, url) {
  if (id && id != '') {
    var div = $(id)
    div.set('html', '')
    new Element('img', { src: url, alt: '' }).inject(div)
  }
  transient.close()
}
function set_sc(sel) {
  var div = sel.getNext();
  switch (sel.selectedIndex) {
    case 1: div.removeClass('yes').removeClass('dunno').addClass('no'); break;
    case 2: div.removeClass('no').removeClass('dunno').addClass('yes'); break;
    default: div.removeClass('yes').removeClass('no').addClass('dunno');
  }
}
