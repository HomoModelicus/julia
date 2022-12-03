
export SpecialCharacterType

# special characters are:
@enum SpecialCharacterType begin
    no_specchar_t

    quote_t             # " ASCII/Unicode U+0022 (category Po Punctuation, other)

    dot_t               # . ASCII/Unicode U+002E (category Po Punctuation, other)
    comma_t             # , ASCII/Unicode U+002C (category Po Punctuation, other)
    colon_t             # : ASCII/Unicode U+003A (category Po Punctuation, other)
    semicolon_t         # ; ASCII/Unicode U+003B (category Po Punctuation, other)
    
    opening_paren_t     # ( ASCII/Unicode U+0028 (category Ps Punctuation, open)
    closing_paren_t     # ) ASCII/Unicode U+0029 (category Pe Punctuation, close)
    
    opening_bracket_t   # [ ASCII/Unicode U+005B (category Ps Punctuation, open)
    closing_bracket_t   # ] ASCII/Unicode U+005D (category Pe Punctuation, close)
    
    opening_curly_t     # { ASCII/Unicode U+007B (category Ps Punctuation, open)
    closing_curly_t     # } ASCII/Unicode U+007D (category Pe Punctuation, close)
    
    plus_t              # + ASCII/Unicode U+002B (category Sm Symbol, math)
    minus_t             # - ASCII/Unicode U+002D (category Pd Punctuation, dash)
    prod_t              # * ASCII/Unicode U+002A (category Po Punctuation, other)
    div_t               # / ASCII/Unicode U+002F (category Po Punctuation, other)
    carot_t             # ^ ASCII/Unicode U+005E (category Sk Symbol, modifier)
    
    less_t              # < ASCII/Unicode U+003C (category Sm Symbol, math)
    greater_t           # > ASCII/Unicode U+003E (category Sm Symbol, math)
    equal_t             # = ASCII/Unicode U+003D (category Sm Symbol, math)
    
    question_mark_t     # ? ASCII/Unicode U+003F (category Po Punctuation, other)
    
    vertical_bar_t      # | ASCII/Unicode U+007C (category Sm Symbol, math)
    ampersand_t         # & ASCII/Unicode U+0026 (category Po Punctuation, other)
    
    exclamation_mark_t  # ! ASCII/Unicode U+0021 (category Po Punctuation, other)

    hashtag_t           # '#': ASCII/Unicode U+0023 (category Po: Punctuation, other)
    dollar_t            # '$': ASCII/Unicode U+0024 (category Sc: Symbol, currency)
    percent_t           # '%': ASCII/Unicode U+0025 (category Po: Punctuation, other)
    backwardslash_t     # '\'': ASCII/Unicode U+0027 (category Po: Punctuation, other)
    # '\\': ASCII/Unicode U+005C (category Po: Punctuation, other)
    at_t                # '@': ASCII/Unicode U+0040 (category Po: Punctuation, other)
    underscore_t        # '_': ASCII/Unicode U+005F (category Pc: Punctuation, connector)
    modifyer_t          # '`': ASCII/Unicode U+0060 (category Sk: Symbol, modifier)
    tilde_t             # '~': ASCII/Unicode U+007E (category Sm: Symbol, math)
end



for inst in instances(SpecialCharacterType)
    @eval export $(Symbol(inst))
end

