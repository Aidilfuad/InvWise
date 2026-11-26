import { useEffect, useId, useRef, useState } from 'react'
import { Check, ChevronDown } from 'lucide-react'

export default function SearchableSelect({
  'aria-label': ariaLabel,
  className = '',
  disabled = false,
  onChange,
  options,
  placeholder = 'Select an option',
  value,
}) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const rootRef = useRef(null)
  const inputRef = useRef(null)
  const listId = useId()
  const selected = options.find((option) => option.value === value)
  const filteredOptions = options.filter((option) => (
    `${option.label} ${option.value}`.toLowerCase().includes(query.trim().toLowerCase())
  ))

  useEffect(() => {
    function handlePointerDown(event) {
      if (!rootRef.current?.contains(event.target)) setOpen(false)
    }
    document.addEventListener('pointerdown', handlePointerDown)
    return () => document.removeEventListener('pointerdown', handlePointerDown)
  }, [])

  function showOptions() {
    if (disabled) return
    setQuery('')
    setOpen(true)
    requestAnimationFrame(() => inputRef.current?.focus())
  }

  function choose(option) {
    onChange(option.value)
    setQuery('')
    setOpen(false)
  }

  function handleKeyDown(event) {
    if (event.key === 'Escape') {
      setOpen(false)
    } else if (event.key === 'Enter' && open && filteredOptions[0]) {
      event.preventDefault()
      choose(filteredOptions[0])
    }
  }

  return (
    <div className="relative min-w-0" ref={rootRef}>
      <div className={`flex min-h-8 items-center rounded-md border border-slate-200 bg-white pr-2 focus-within:border-teal-500 ${disabled ? 'cursor-not-allowed bg-slate-50 opacity-60' : ''} ${className}`}>
        <input
          aria-label={ariaLabel}
          aria-controls={listId}
          aria-expanded={open}
          aria-haspopup="listbox"
          autoComplete="off"
          className="h-full min-h-8 min-w-0 flex-1 bg-transparent px-3 text-inherit outline-none placeholder:text-slate-400"
          disabled={disabled}
          onChange={(event) => {
            setQuery(event.target.value)
            setOpen(true)
          }}
          onFocus={showOptions}
          onKeyDown={handleKeyDown}
          placeholder={open ? 'Type to filter…' : placeholder}
          ref={inputRef}
          role="combobox"
          value={open ? query : selected?.label ?? ''}
        />
        <button
          aria-label={open ? 'Close options' : 'Show options'}
          className="grid h-6 w-6 shrink-0 place-items-center text-slate-400"
          disabled={disabled}
          onClick={() => open ? setOpen(false) : showOptions()}
          tabIndex={-1}
          type="button"
        >
          <ChevronDown aria-hidden="true" size={14} />
        </button>
      </div>
      {open && (
        <div className="absolute left-0 right-0 top-full z-[90] mt-1 max-h-56 overflow-y-auto rounded-md border border-slate-200 bg-white py-1 shadow-xl">
          <ul id={listId} role="listbox">
            {filteredOptions.length ? filteredOptions.map((option) => (
              <li key={option.value} role="option" aria-selected={option.value === value}>
                <button
                  className="flex w-full items-center justify-between gap-2 px-3 py-2 text-left text-xs text-slate-700 hover:bg-teal-50"
                  onMouseDown={(event) => event.preventDefault()}
                  onClick={() => choose(option)}
                  type="button"
                >
                  <span className="truncate">{option.label}</span>
                  {option.value === value && <Check aria-hidden="true" className="shrink-0 text-teal-600" size={13} />}
                </button>
              </li>
            )) : (
              <li className="px-3 py-2 text-xs text-slate-400">No matching options.</li>
            )}
          </ul>
        </div>
      )}
    </div>
  )
}
