export default function HubSummaryCards({ cards }) {
  return (
    <section aria-label="Summary metrics" className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map(({ Icon, label, value, note, tone = 'teal' }) => {
        const tones = {
          teal: 'bg-teal-50 text-teal-700',
          red: 'bg-rose-50 text-rose-600',
          amber: 'bg-amber-50 text-amber-700',
          blue: 'bg-blue-50 text-blue-700',
          green: 'bg-emerald-50 text-emerald-700',
          slate: 'bg-slate-100 text-slate-600',
        }
        return (
          <article className="rounded-lg border border-slate-200 bg-white px-3.5 py-3.5 shadow-[0_1px_2px_rgba(15,23,42,0.02)] sm:px-4" key={label}>
            <p className="text-[10px] font-medium text-slate-500">{label}</p>
            <div className="mt-1 flex items-end justify-between gap-2">
              <p className="text-[21px] font-semibold leading-6 tracking-[-0.03em] text-slate-900">{value}</p>
              <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-md ${tones[tone] || tones.teal}`}>
                <Icon size={15} strokeWidth={1.9} />
              </span>
            </div>
            {note && <p className="mt-1 text-[9px] text-slate-500">{note}</p>}
          </article>
        )
      })}
    </section>
  )
}
