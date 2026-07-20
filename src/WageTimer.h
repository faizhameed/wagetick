#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <QElapsedTimer>

/**
 * Core wage engine: tracks elapsed work time and converts an hourly rate
 * into live earnings (updated every second while running).
 */
class WageTimer : public QObject {
    Q_OBJECT

    Q_PROPERTY(double hourlyRate READ hourlyRate WRITE setHourlyRate NOTIFY hourlyRateChanged)
    Q_PROPERTY(QString currency READ currency WRITE setCurrency NOTIFY currencyChanged)
    Q_PROPERTY(QString currencySymbol READ currencySymbol NOTIFY currencyChanged)
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)
    Q_PROPERTY(double earned READ earned NOTIFY tick)
    Q_PROPERTY(double perSecond READ perSecond NOTIFY hourlyRateChanged)
    Q_PROPERTY(qint64 elapsedSeconds READ elapsedSeconds NOTIFY tick)
    Q_PROPERTY(QString formattedEarned READ formattedEarned NOTIFY tick)
    Q_PROPERTY(QString formattedElapsed READ formattedElapsed NOTIFY tick)
    Q_PROPERTY(QString formattedPerSecond READ formattedPerSecond NOTIFY hourlyRateChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY runningChanged)

public:
    explicit WageTimer(QObject *parent = nullptr);

    double hourlyRate() const { return m_hourlyRate; }
    void setHourlyRate(double rate);

    QString currency() const { return m_currency; }
    void setCurrency(const QString &code);

    QString currencySymbol() const;
    bool isRunning() const { return m_running; }

    double earned() const;
    double perSecond() const;
    qint64 elapsedSeconds() const;
    qint64 elapsedMilliseconds() const;

    QString formattedEarned() const;
    QString formattedElapsed() const;
    QString formattedPerSecond() const;
    QString statusText() const;

public slots:
    void start();
    void stop();
    void reset();
    void toggle();

signals:
    void hourlyRateChanged();
    void currencyChanged();
    void runningChanged();
    void tick();

private:
    void onTick();

    double m_hourlyRate = 50.0;
    QString m_currency = QStringLiteral("USD");
    bool m_running = false;
    qint64 m_accumulatedMs = 0;
    QElapsedTimer m_session;
    QTimer m_uiTimer;
};
