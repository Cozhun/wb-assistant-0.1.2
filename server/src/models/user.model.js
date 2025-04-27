import { BaseModel } from './base.model.js';

export class UserModel extends BaseModel {
  // Получение пользователя по ID
  static async getById(userId) {
    const sql = `
      SELECT * FROM Users
      WHERE UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение пользователя по email и enterpriseId
  static async getByEmail(email, enterpriseId) {
    const sql = `
      SELECT * FROM Users
      WHERE Email = $1 AND EnterpriseId = $2
    `;
    const result = await this.query(sql, [email, enterpriseId]);
    return result.rows.length ? result.rows[0] : null;
  }

  // Получение всех пользователей предприятия
  static async getByEnterpriseId(enterpriseId) {
    const sql = `
      SELECT * FROM Users
      WHERE EnterpriseId = $1
      ORDER BY UserId
    `;
    const result = await this.query(sql, [enterpriseId]);
    return result.rows;
  }

  // Создание нового пользователя
  static async create(user) {
    const sql = `
      INSERT INTO Users (
        EnterpriseId, Email, PasswordHash, FirstName, LastName,
        PhoneNumber, IsActive, TwoFactorEnabled
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8
      ) RETURNING *
    `;
    const result = await this.query(sql, [
      user.enterpriseId,
      user.email,
      user.passwordHash,
      user.firstName || null,
      user.lastName || null,
      user.phoneNumber || null,
      user.isActive === undefined ? true : user.isActive,
      user.twoFactorEnabled === undefined ? false : user.twoFactorEnabled
    ]);
    return result.rows[0];
  }

  // Обновление пользователя
  static async update(userId, user) {
    const fields = [];
    const values = [];
    let paramIndex = 1;

    if (user.email !== undefined) {
      fields.push(`Email = $${paramIndex++}`);
      values.push(user.email);
    }
    if (user.passwordHash !== undefined) {
      fields.push(`PasswordHash = $${paramIndex++}`);
      values.push(user.passwordHash);
    }
    if (user.firstName !== undefined) {
      fields.push(`FirstName = $${paramIndex++}`);
      values.push(user.firstName);
    }
    if (user.lastName !== undefined) {
      fields.push(`LastName = $${paramIndex++}`);
      values.push(user.lastName);
    }
    if (user.phoneNumber !== undefined) {
      fields.push(`PhoneNumber = $${paramIndex++}`);
      values.push(user.phoneNumber);
    }
    if (user.isActive !== undefined) {
      fields.push(`IsActive = $${paramIndex++}`);
      values.push(user.isActive);
    }
    if (user.lastLoginAt !== undefined) {
      fields.push(`LastLoginAt = $${paramIndex++}`);
      values.push(user.lastLoginAt);
    }
    if (user.twoFactorEnabled !== undefined) {
      fields.push(`TwoFactorEnabled = $${paramIndex++}`);
      values.push(user.twoFactorEnabled);
    }
    if (user.refreshToken !== undefined) {
      fields.push(`RefreshToken = $${paramIndex++}`);
      values.push(user.refreshToken);
    }
    if (user.refreshTokenExpiresAt !== undefined) {
      fields.push(`RefreshTokenExpiresAt = $${paramIndex++}`);
      values.push(user.refreshTokenExpiresAt);
    }

    if (fields.length === 0) {
      return this.getById(userId);
    }

    const sql = `
      UPDATE Users
      SET ${fields.join(', ')}
      WHERE UserId = $${paramIndex}
      RETURNING *
    `;
    values.push(userId);

    const result = await this.query(sql, values);
    return result.rows.length ? result.rows[0] : null;
  }

  // Обновление времени последнего входа
  static async updateLastLogin(userId) {
    const sql = `
      UPDATE Users
      SET LastLoginAt = CURRENT_TIMESTAMP
      WHERE UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rowCount > 0;
  }

  // Удаление пользователя (логическое)
  static async delete(userId) {
    const sql = `
      UPDATE Users
      SET IsActive = FALSE
      WHERE UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rowCount > 0;
  }

  // Получение всех ролей
  static async getAllRoles() {
    const sql = `
      SELECT * FROM Roles
      ORDER BY RoleId
    `;
    const result = await this.query(sql);
    return result.rows;
  }

  // Получение ролей пользователя
  static async getUserRoles(userId) {
    const sql = `
      SELECT r.*
      FROM Roles r
      JOIN UserRoles ur ON r.RoleId = ur.RoleId
      WHERE ur.UserId = $1
    `;
    const result = await this.query(sql, [userId]);
    return result.rows;
  }

  // Добавление роли пользователю
  static async addUserRole(userId, roleId) {
    const sql = `
      INSERT INTO UserRoles (UserId, RoleId)
      VALUES ($1, $2)
      ON CONFLICT (UserId, RoleId) DO NOTHING
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rowCount > 0;
  }

  // Удаление роли у пользователя
  static async removeUserRole(userId, roleId) {
    const sql = `
      DELETE FROM UserRoles
      WHERE UserId = $1 AND RoleId = $2
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rowCount > 0;
  }

  // Проверка, имеет ли пользователь роль
  static async hasRole(userId, roleId) {
    const sql = `
      SELECT 1 FROM UserRoles
      WHERE UserId = $1 AND RoleId = $2
    `;
    const result = await this.query(sql, [userId, roleId]);
    return result.rows.length > 0;
  }

  // Получение всех активных пользователей с определенной ролью
  static async getUsersByRole(enterpriseId, roleId) {
    const sql = `
      SELECT u.*
      FROM Users u
      JOIN UserRoles ur ON u.UserId = ur.UserId
      WHERE u.EnterpriseId = $1 AND ur.RoleId = $2 AND u.IsActive = TRUE
    `;
    const result = await this.query(sql, [enterpriseId, roleId]);
    return result.rows;
  }
} 
