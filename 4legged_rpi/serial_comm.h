#ifndef SERIAL_COMM_H
#define SERIAL_COMM_H

#include <QTime>
#include <QElapsedTimer>

#include <QObject>
#include <QtSerialPort/QSerialPort>

class SerialCommunication : public QObject
{
    Q_OBJECT

    QTime time;
    QElapsedTimer timens;
    QSerialPort serial;
    QString unfinished_line;

signals:
    void dataSeparated(QString);

public:
    SerialCommunication();

public slots:
    void readData();
    void sendData(const QByteArray &);

    void openSerialPort();
    void closeSerialPort();
};

#endif // SERIAL_COMM_H
