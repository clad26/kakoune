# http://julialang.org
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*\.(jl) %{
    set-option buffer filetype julia
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=julia %{
    require-module julia
    
    hook window ModeChange pop:insert:.* -group lua-trim-indent lua-trim-indent
    hook window InsertChar .* -group lua-indent lua-indent-on-char
    hook window InsertChar \n -group lua-indent lua-indent-on-new-line
    hook window InsertChar \n -group lua-insert lua-insert-on-new-line

}

hook -group julia-highlight global WinSetOption filetype=julia %{
    add-highlighter window/julia ref julia
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/julia }
}


provide-module julia %{

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/julia regions
add-highlighter shared/julia/code default-region group
add-highlighter shared/julia/string  region '"' (?<!\\)(\\\\)*"         fill string
add-highlighter shared/julia/comment region '#' '$'                     fill comment

# taken from https://github.com/JuliaLang/julia/blob/master/contrib/julia-mode.el
add-highlighter shared/julia/code/ regex %{\b(true|false|C_NULL|Inf|NaN|Inf32|NaN32|nothing|\b-?\d+[fdiu]?)\b} 0:value
add-highlighter shared/julia/code/ regex \b(if|else|elseif|while|for|begin|end|quote|try|catch|return|local|abstract|function|macro|ccall|finally|typealias|break|continue|type|global|module|using|import|export|const|let|bitstype|do|in|baremodule|importall|immutable|mutable|struct)\b 0:keyword
add-highlighter shared/julia/code/ regex \b(Number|Real|BigInt|Integer|UInt|UInt8|UInt16|UInt32|UInt64|UInt128|Int|Int8|Int16|Int32|Int64|Int128|BigFloat|FloatingPoint|Float16|Float32|Float64|Complex128|Complex64|Bool|Cuchar|Cshort|Cushort|Cint|Cuint|Clonglong|Culonglong|Cintmax_t|Cuintmax_t|Cfloat|Cdouble|Cptrdiff_t|Cssize_t|Csize_t|Cchar|Clong|Culong|Cwchar_t|Char|ASCIIString|UTF8String|ByteString|SubString|AbstractString|Array|DArray|AbstractArray|AbstractVector|AbstractMatrix|AbstractSparseMatrix|SubArray|StridedArray|StridedVector|StridedMatrix|VecOrMat|StridedVecOrMat|DenseArray|SparseMatrixCSC|BitArray|Range|OrdinalRange|StepRange|UnitRange|FloatRange|Tuple|NTuple|Vararg|DataType|Symbol|Function|Vector|Matrix|Union|Type|Any|Complex|String|Ptr|Void|Exception|Task|Signed|Unsigned|Associative|Dict|IO|IOStream|Rational|Regex|RegexMatch|Set|IntSet|Expr|WeakRef|ObjectIdDict|AbstractRNG|MersenneTwister)\b 0:type

define-command -hidden lua-trim-indent %{
    # remove trailing whitespaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden lua-indent-on-char %{
    evaluate-commands -no-hooks -draft -itersel %{
        # align middle and end structures to start and indent when necessary, elseif is already covered by else
        try %{ execute-keys -draft <a-x><a-k>^\h*(else)$<ret><a-semicolon><a-?>^\h*(if)<ret>s\A|.\z<ret>)<a-&> }
        try %{ execute-keys -draft <a-x><a-k>^\h*(end)$<ret><a-semicolon><a-?>^\h*(for|function|if|while)<ret>s\A|.\z<ret>)<a-&> }
    }
}

define-command -hidden lua-indent-on-new-line %{
    evaluate-commands -no-hooks -draft -itersel %{
        # remove trailing white spaces from previous line
        try %{ execute-keys -draft k : lua-trim-indent <ret> }
        # preserve previous non-empty line indent
        try %{ execute-keys -draft <space><a-?>^[^\n]+$<ret>s\A|.\z<ret>)<a-&> }
        # indent after start structure
        try %{ execute-keys -draft <a-?>^[^\n]*\w+[^\n]*$<ret><a-k>^\h*(else|elseif|for|function|if|while)\b<ret><a-:><semicolon><a-gt> }
    }
}

define-command -hidden lua-insert-on-new-line %[
    evaluate-commands -no-hooks -draft -itersel %[
        # copy -- comment prefix and following white spaces
        try %{ execute-keys -draft k<a-x>s^\h*\K--\h*<ret>yghjP }
        # wisely add end structure
        evaluate-commands -save-regs x %[
            try %{ execute-keys -draft k<a-x>s^\h+<ret>"xy } catch %{ reg x '' } # Save previous line indent in register x
            try %[ execute-keys -draft k<a-x> <a-k>^<c-r>x(for|function|if|while)<ret> J}iJ<a-x> <a-K>^<c-r>x(else|end|elseif)$<ret> # Validate previous line and that it is not closed yet
                   execute-keys -draft o<c-r>xend<esc> ] # auto insert end
        ]
    ]
]

}
