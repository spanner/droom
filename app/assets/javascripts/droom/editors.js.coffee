#= require medium-editor/dist/js/medium-editor

jQuery ($) ->

  $.fn.html_editable = ()->
    editor = new MediumEditor @,
      placeholder: false
      autoLink: true
      imageDragging: false
      anchor:
        customClassOption: null
        customClassOptionText: 'Button'
        linkValidation: false
        placeholderText: 'URL...'
        targetCheckbox: false
      anchorPreview: false
      paste:
        forcePlainText: false
        cleanPastedHTML: true
        cleanReplacements: []
        cleanAttrs: ['class', 'style', 'dir']
        cleanTags: ['meta']
      toolbar:
        updateOnEmptySelection: true
        allowMultiParagraphSelection: true
        buttons: [
          name: 'bold'
          contentDefault: '<svg><use xlink:href="#bold_button"></use></svg>'
        ,
          name: 'italic'
          contentDefault: '<svg><use xlink:href="#italic_button"></use></svg>'
        ,
          name: 'anchor'
          contentDefault: '<svg><use xlink:href="#anchor_button"></use></svg>'
        ,
          name: 'orderedlist'
          contentDefault: '<svg><use xlink:href="#ol_button"></use></svg>'
        ,
          name: 'unorderedlist'
          contentDefault: '<svg><use xlink:href="#ul_button"></use></svg>'
        ,
          name: 'h2'
          contentDefault: '<svg><use xlink:href="#h1_button"></use></svg>'
        ,
          name: 'h3'
          contentDefault: '<svg><use xlink:href="#h2_button"></use></svg>'
        ,
          name: 'removeFormat'
          contentDefault: '<svg><use xlink:href="#clear_button"></use></svg>'
        ]

