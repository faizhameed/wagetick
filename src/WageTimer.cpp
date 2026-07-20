#include "WageTimer.h"

#include <QByteArray>
#include <QtGlobal>

#include <algorithm>
#include <cmath>

namespace {
bool nearlyEqual(double a, double b)
{
    return std::abs(a - b) < 1e-9;
}
} // namespace

WageTimer::WageTimer(QObject *parent)
    : QObject(parent)
{
    // UI refreshes often so sub-second earnings still animate smoothly.
    // Accrual itself is driven by a high-resolution elapsed clock.
    m_uiTimer.setInterval(100);
    connect(&m_uiTimer, &QTimer::timeout, this, &WageTimer::onTick);

    // Optional: seed elapsed time for README/screenshots (e.g. 1h20m45s).
    // WAGETICK_SCREENSHOT_ELAPSED_MS=4845000
    if (const QByteArray seed = qgetenv("WAGETICK_SCREENSHOT_ELAPSED_MS"); !seed.isEmpty()) {
        bool ok = false;
        const qint64 ms = QString::fromUtf8(seed).toLongLong(&ok);
        if (ok && ms >= 0)
            m_accumulatedMs = ms;
    }
}

void WageTimer::setHourlyRate(double rate)
{
    rate = std::clamp(rate, 0.0, 1000000.0);
    if (nearlyEqual(m_hourlyRate, rate))
        return;
    m_hourlyRate = rate;
    emit hourlyRateChanged();
    emit tick();
}

void WageTimer::setCurrency(const QString &code)
{
    const QString upper = code.trimmed().toUpper();
    if (upper != QLatin1String("USD")
        && upper != QLatin1String("EUR")
        && upper != QLatin1String("GBP")) {
        return;
    }
    if (m_currency == upper)
        return;
    m_currency = upper;
    emit currencyChanged();
    emit tick();
}

QString WageTimer::currencySymbol() const
{
    if (m_currency == QLatin1String("EUR"))
        return QStringLiteral("€");
    if (m_currency == QLatin1String("GBP"))
        return QStringLiteral("£");
    return QStringLiteral("$");
}

qint64 WageTimer::elapsedMilliseconds() const
{
    qint64 ms = m_accumulatedMs;
    if (m_running && m_session.isValid())
        ms += m_session.elapsed();
    return ms;
}

qint64 WageTimer::elapsedSeconds() const
{
    return elapsedMilliseconds() / 1000;
}

double WageTimer::perSecond() const
{
    return m_hourlyRate / 3600.0;
}

double WageTimer::earned() const
{
    // earned = hours_worked * hourly_rate
    // hours_worked = ms / 3_600_000
    return (static_cast<double>(elapsedMilliseconds()) / 3600000.0) * m_hourlyRate;
}

QString WageTimer::formattedEarned() const
{
    return QStringLiteral("%1%2")
        .arg(currencySymbol())
        .arg(earned(), 0, 'f', 4);
}

QString WageTimer::formattedPerSecond() const
{
    return QStringLiteral("%1%2/s")
        .arg(currencySymbol())
        .arg(perSecond(), 0, 'f', 6);
}

QString WageTimer::formattedElapsed() const
{
    const qint64 total = elapsedSeconds();
    const qint64 h = total / 3600;
    const qint64 m = (total % 3600) / 60;
    const qint64 s = total % 60;
    return QStringLiteral("%1:%2:%3")
        .arg(h, 2, 10, QChar('0'))
        .arg(m, 2, 10, QChar('0'))
        .arg(s, 2, 10, QChar('0'));
}

QString WageTimer::statusText() const
{
    return m_running ? QStringLiteral("Earning…") : QStringLiteral("Paused");
}

void WageTimer::start()
{
    if (m_running)
        return;
    if (m_hourlyRate <= 0.0)
        return;

    m_running = true;
    m_session.restart();
    m_uiTimer.start();
    emit runningChanged();
    emit tick();
}

void WageTimer::stop()
{
    if (!m_running)
        return;

    if (m_session.isValid())
        m_accumulatedMs += m_session.elapsed();

    m_running = false;
    m_uiTimer.stop();
    emit runningChanged();
    emit tick();
}

void WageTimer::reset()
{
    m_uiTimer.stop();
    m_running = false;
    m_accumulatedMs = 0;
    m_session.invalidate();
    emit runningChanged();
    emit tick();
}

void WageTimer::toggle()
{
    if (m_running)
        stop();
    else
        start();
}

void WageTimer::onTick()
{
    emit tick();
}
