-- SpiderOS: memoria usada en MB -> "MEM: 672.4M"

local function formato(mb)
  if mb >= 1024 * 100 then
    return string.format("%.1fG", mb / 1024)
  end
  return string.format("%.1fM", mb)
end

function update()
  noctalia.setUpdateInterval(2000)

  local stats = noctalia.systemStats()
  if stats == nil or stats.ram == nil or stats.ram.usedMb == nil then
    barWidget.setText("MEM: --")
    return
  end

  barWidget.setText("MEM: " .. formato(stats.ram.usedMb))
  barWidget.setTooltip({
    { "Usada", string.format("%.0f MB", stats.ram.usedMb) },
    { "Total", string.format("%.0f MB", stats.ram.totalMb or 0) },
    { "Uso", string.format("%.0f%%", stats.ram.usagePercent or 0) },
  })
end
